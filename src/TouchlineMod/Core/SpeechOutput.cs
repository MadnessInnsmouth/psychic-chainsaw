using System;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;
using BepInEx.Logging;

namespace TouchlineMod.Core
{
    /// <summary>
    /// Provides speech output via screen readers (Tolk/NVDA/JAWS) with SAPI fallback.
    /// Tolk is a screen reader abstraction library that supports NVDA, JAWS, and others.
    /// If Tolk is unavailable, falls back to Windows SAPI via COM interop.
    /// </summary>
    public static class SpeechOutput
    {
        private static ManualLogSource Log => Plugin.Log;
        private static bool _initialized;
        private static bool _tolkAvailable;
        private static bool _sapiAvailable;

        #region Windows DLL Loading

        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern bool SetDllDirectory(string lpPathName);

        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern IntPtr AddDllDirectory(string lpPathName);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool SetDefaultDllDirectories(uint directoryFlags);

        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern IntPtr LoadLibrary(string lpFileName);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool FreeLibrary(IntPtr hModule);

        private const uint LOAD_LIBRARY_SEARCH_DEFAULT_DIRS = 0x00001000;
        private static IntPtr _tolkLibraryHandle = IntPtr.Zero;

        /// <summary>
        /// Static constructor to set up DLL search path before any P/Invoke calls.
        /// This ensures Tolk.dll and its dependencies are loaded from the mod folder.
        /// </summary>
        static SpeechOutput()
        {
            try
            {
                // Get the directory where this assembly (TouchlineMod.dll) is located
                string assemblyLocation = Assembly.GetExecutingAssembly().Location;
                string modDirectory = Path.GetDirectoryName(assemblyLocation);

                if (!string.IsNullOrEmpty(modDirectory) && Directory.Exists(modDirectory))
                {
                    // Use AddDllDirectory instead of SetDllDirectory to preserve default search paths
                    // This is safer and doesn't break loading of other DLLs
                    try
                    {
                        // Per Windows documentation: AddDllDirectory must be called before SetDefaultDllDirectories
                        AddDllDirectory(modDirectory);
                        SetDefaultDllDirectories(LOAD_LIBRARY_SEARCH_DEFAULT_DIRS);
                    }
                    catch (EntryPointNotFoundException)
                    {
                        // AddDllDirectory is not available on older Windows versions, fall back to SetDllDirectory
                        SetDllDirectory(modDirectory);
                    }

                    // Pre-load Tolk.dll from the mod directory to ensure it's found
                    string tolkPath = Path.Combine(modDirectory, "Tolk.dll");
                    if (File.Exists(tolkPath))
                    {
                        _tolkLibraryHandle = LoadLibrary(tolkPath);
                        if (_tolkLibraryHandle == IntPtr.Zero)
                        {
                            int errorCode = Marshal.GetLastWin32Error();
                            Console.WriteLine($"[Touchline] Warning: Failed to pre-load Tolk.dll (error code: {errorCode}). Will attempt standard loading.");
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                // If this fails, we'll fall back to the default DLL search behavior
                // The Log may not be initialized yet, so we can't log here
                Console.WriteLine($"[Touchline] Failed to set DLL directory: {ex.Message}");
            }
        }

        /// <summary>
        /// Clean up the manually loaded Tolk library handle.
        /// </summary>
        private static void CleanupTolkLibrary()
        {
            if (_tolkLibraryHandle != IntPtr.Zero)
            {
                try
                {
                    FreeLibrary(_tolkLibraryHandle);
                    _tolkLibraryHandle = IntPtr.Zero;
                }
                catch (Exception ex)
                {
                    Log?.LogWarning($"Failed to free Tolk library: {ex.Message}");
                }
            }
        }

        #endregion

        #region Tolk Native Methods

        [DllImport("Tolk.dll", CallingConvention = CallingConvention.Cdecl)]
        private static extern void Tolk_Load();

        [DllImport("Tolk.dll", CallingConvention = CallingConvention.Cdecl)]
        private static extern void Tolk_Unload();

        [DllImport("Tolk.dll", CallingConvention = CallingConvention.Cdecl)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool Tolk_HasSpeech();

        [DllImport("Tolk.dll", CallingConvention = CallingConvention.Cdecl)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool Tolk_Output(
            [MarshalAs(UnmanagedType.LPWStr)] string str,
            [MarshalAs(UnmanagedType.Bool)] bool interrupt);

        [DllImport("Tolk.dll", CallingConvention = CallingConvention.Cdecl)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool Tolk_Speak(
            [MarshalAs(UnmanagedType.LPWStr)] string str,
            [MarshalAs(UnmanagedType.Bool)] bool interrupt);

        [DllImport("Tolk.dll", CallingConvention = CallingConvention.Cdecl)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool Tolk_Silence();

        [DllImport("Tolk.dll", CallingConvention = CallingConvention.Cdecl)]
        private static extern IntPtr Tolk_DetectScreenReader();

        #endregion

        #region Windows SAPI COM Interop

        [DllImport("ole32.dll")]
        private static extern int CoInitializeEx(IntPtr pvReserved, uint dwCoInit);

        [DllImport("ole32.dll")]
        private static extern void CoUninitialize();

        [DllImport("ole32.dll")]
        private static extern int CoCreateInstance(
            [In] ref Guid rclsid,
            IntPtr pUnkOuter,
            uint dwClsContext,
            [In] ref Guid riid,
            out IntPtr ppv);

        // ISpVoice CLSID and IID for Windows SAPI
        private static readonly Guid CLSID_SpVoice = new Guid("96749377-3391-11D2-9EE3-00C04F797396");
        private static readonly Guid IID_ISpVoice = new Guid("6C44DF74-72B9-4992-A1EC-EF996E0422D4");
        private static IntPtr _sapiVoice = IntPtr.Zero;

        // ISpVoice::Speak is the 21st method in the vtable (index 20)
        private delegate int SpVoiceSpeakDelegate(
            IntPtr pThis,
            [MarshalAs(UnmanagedType.LPWStr)] string pwcs,
            uint dwFlags,
            out uint pulStreamNumber);

        private const uint SPF_ASYNC = 0x1;
        private const uint SPF_PURGEBEFORESPEAK = 0x2;

        #endregion

        /// <summary>
        /// Initialize the speech output system. Tries Tolk first, then SAPI.
        /// </summary>
        /// <returns>True if any speech backend is available.</returns>
        public static bool Initialize()
        {
            if (_initialized) return _tolkAvailable || _sapiAvailable;

            _tolkAvailable = TryInitializeTolk();
            if (!_tolkAvailable)
            {
                _sapiAvailable = TryInitializeSapi();
            }

            _initialized = true;
            return _tolkAvailable || _sapiAvailable;
        }

        private static bool TryInitializeTolk()
        {
            try
            {
                Tolk_Load();
                if (Tolk_HasSpeech())
                {
                    IntPtr readerPtr = Tolk_DetectScreenReader();
                    string readerName = readerPtr != IntPtr.Zero
                        ? Marshal.PtrToStringUni(readerPtr) ?? "Unknown"
                        : "Unknown";
                    Log.LogInfo($"Tolk connected to screen reader: {readerName}");
                    return true;
                }
                Tolk_Unload();
                Log.LogInfo("Tolk loaded but no screen reader detected");
            }
            catch (DllNotFoundException)
            {
                Log.LogInfo("Tolk.dll not found - screen reader integration unavailable");
            }
            catch (Exception ex)
            {
                Log.LogWarning($"Tolk initialization failed: {ex.Message}");
            }
            return false;
        }

        private static bool TryInitializeSapi()
        {
            if (!RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
            {
                Log.LogInfo("SAPI not available on this platform");
                return false;
            }

            try
            {
                CoInitializeEx(IntPtr.Zero, 0);
                Guid clsid = CLSID_SpVoice;
                Guid iid = IID_ISpVoice;
                int hr = CoCreateInstance(ref clsid, IntPtr.Zero, 1, ref iid, out _sapiVoice);
                if (hr == 0 && _sapiVoice != IntPtr.Zero)
                {
                    Log.LogInfo("Windows SAPI initialized as fallback");
                    return true;
                }
                Log.LogWarning($"SAPI CoCreateInstance returned HRESULT 0x{hr:X8}");
            }
            catch (Exception ex)
            {
                Log.LogWarning($"SAPI initialization failed: {ex.Message}");
            }
            return false;
        }

        /// <summary>
        /// Speak text through the active speech backend.
        /// </summary>
        /// <param name="text">Text to speak.</param>
        /// <param name="interrupt">If true, stop current speech first.</param>
        public static void Speak(string text, bool interrupt = true)
        {
            if (string.IsNullOrWhiteSpace(text)) return;
            if (!Config.TouchlineConfig.SpeechEnabled.Value) return;

            if (interrupt && Config.TouchlineConfig.InterruptOnNew.Value)
            {
                Silence();
            }

            if (_tolkAvailable)
            {
                try
                {
                    Tolk_Speak(text, interrupt);
                    return;
                }
                catch (Exception ex)
                {
                    Log.LogWarning($"Tolk speak failed: {ex.Message}");
                }
            }

            if (_sapiAvailable && _sapiVoice != IntPtr.Zero)
            {
                try
                {
                    SpeakSapi(text, interrupt);
                    return;
                }
                catch (Exception ex)
                {
                    Log.LogWarning($"SAPI speak failed: {ex.Message}");
                }
            }

            // Fallback: log the text
            Log.LogInfo($"[Speech] {text}");
        }

        /// <summary>
        /// Output text to screen reader (speech + braille if available).
        /// </summary>
        public static void Output(string text, bool interrupt = true)
        {
            if (string.IsNullOrWhiteSpace(text)) return;
            if (!Config.TouchlineConfig.SpeechEnabled.Value) return;

            if (_tolkAvailable)
            {
                try
                {
                    Tolk_Output(text, interrupt);
                    return;
                }
                catch (Exception ex)
                {
                    Log.LogWarning($"Tolk output failed: {ex.Message}");
                }
            }

            // Fall through to speak-only
            Speak(text, interrupt);
        }

        /// <summary>
        /// Stop all current speech output.
        /// </summary>
        public static void Silence()
        {
            if (_tolkAvailable)
            {
                try { Tolk_Silence(); } catch { }
            }
        }

        /// <summary>
        /// Clean up all speech resources.
        /// </summary>
        public static void Shutdown()
        {
            if (_tolkAvailable)
            {
                try { Tolk_Unload(); } catch { }
                _tolkAvailable = false;
            }

            if (_sapiAvailable && _sapiVoice != IntPtr.Zero)
            {
                try
                {
                    Marshal.Release(_sapiVoice);
                    CoUninitialize();
                }
                catch { }
                _sapiVoice = IntPtr.Zero;
                _sapiAvailable = false;
            }

            CleanupTolkLibrary();
            _initialized = false;
        }

        private static void SpeakSapi(string text, bool interrupt)
        {
            if (_sapiVoice == IntPtr.Zero) return;

            // Get ISpVoice vtable
            IntPtr vtable = Marshal.ReadIntPtr(_sapiVoice);
            // ISpVoice::Speak is at vtable index 20
            IntPtr speakPtr = Marshal.ReadIntPtr(vtable, 20 * IntPtr.Size);
            var speakFunc = Marshal.GetDelegateForFunctionPointer<SpVoiceSpeakDelegate>(speakPtr);

            uint flags = SPF_ASYNC;
            if (interrupt) flags |= SPF_PURGEBEFORESPEAK;

            speakFunc(_sapiVoice, text, flags, out _);
        }
    }
}
