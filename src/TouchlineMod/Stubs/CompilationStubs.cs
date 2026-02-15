// Stub types for compilation without BepInEx/Unity/Harmony installed.
// These are replaced by real assemblies when building against the game.
// See BUILDING.md for instructions on building with game DLLs.
//
// This file is only compiled when UseGameRefs is false (no game installation found).

#if !USE_GAME_REFS

using System;
using System.Collections.Generic;
using System.Reflection;

// ============================================================================
// BepInEx stubs
// ============================================================================
namespace BepInEx
{
    [AttributeUsage(AttributeTargets.Class)]
    public class BepInPlugin : Attribute
    {
        public string GUID { get; }
        public string Name { get; }
        public string Version { get; }
        public BepInPlugin(string guid, string name, string version)
        {
            GUID = guid;
            Name = name;
            Version = version;
        }
    }

    public abstract class BaseUnityPlugin : UnityEngine.MonoBehaviour
    {
        public BepInEx.Configuration.ConfigFile Config { get; } = new BepInEx.Configuration.ConfigFile();
        public BepInEx.Logging.ManualLogSource Logger { get; } = new BepInEx.Logging.ManualLogSource("Plugin");
    }
}

namespace BepInEx.Logging
{
    public class ManualLogSource
    {
        public string SourceName { get; }
        public ManualLogSource(string name) { SourceName = name; }
        public void LogInfo(object data) { Console.WriteLine($"[Info] {data}"); }
        public void LogWarning(object data) { Console.WriteLine($"[Warn] {data}"); }
        public void LogError(object data) { Console.Error.WriteLine($"[Error] {data}"); }
    }
}

namespace BepInEx.Configuration
{
    public class ConfigFile
    {
        public ConfigEntry<T> Bind<T>(string section, string key, T defaultValue, string description = "")
        {
            return new ConfigEntry<T>(defaultValue);
        }
        public ConfigEntry<T> Bind<T>(string section, string key, T defaultValue, ConfigDescription description)
        {
            return new ConfigEntry<T>(defaultValue);
        }
    }

    public class ConfigEntry<T>
    {
        public T Value { get; set; }
        public ConfigEntry(T defaultValue) { Value = defaultValue; }
    }

    public class ConfigDescription
    {
        public string Description { get; }
        public ConfigDescription(string description, AcceptableValueBase acceptableValues = null)
        {
            Description = description;
        }
    }

    public abstract class AcceptableValueBase { }

    public class AcceptableValueRange<T> : AcceptableValueBase where T : IComparable
    {
        public T MinValue { get; }
        public T MaxValue { get; }
        public AcceptableValueRange(T min, T max) { MinValue = min; MaxValue = max; }
    }
}

// ============================================================================
// HarmonyX stubs
// ============================================================================
namespace HarmonyLib
{
    public class Harmony
    {
        public string Id { get; }
        public Harmony(string id) { Id = id; }
        public void PatchAll() { }
        public void UnpatchSelf() { }
        public void Patch(MethodBase original, HarmonyMethod prefix = null,
            HarmonyMethod postfix = null, HarmonyMethod transpiler = null) { }
        public IEnumerable<MethodBase> GetPatchedMethods() { yield break; }
    }

    public class HarmonyMethod
    {
        public MethodInfo method;
        public HarmonyMethod(Type type, string name)
        {
            method = type.GetMethod(name, BindingFlags.Static | BindingFlags.NonPublic | BindingFlags.Public);
        }
    }

    public static class AccessTools
    {
        public static MethodInfo Method(Type type, string name) => type?.GetMethod(name);
        public static MethodInfo PropertySetter(Type type, string name) => type?.GetProperty(name)?.SetMethod;
    }
}

// ============================================================================
// UnityEngine stubs
// ============================================================================
namespace UnityEngine
{
    public class Object
    {
        public string name { get; set; } = "";
        public static void Destroy(Object obj) { }
        public static void DontDestroyOnLoad(Object target) { }
    }

    public class Component : Object
    {
        public GameObject gameObject { get; internal set; } = new GameObject();
        public Transform transform { get; internal set; } = new Transform();
        public T GetComponent<T>() where T : class => default;
        public T GetComponentInChildren<T>() where T : class => default;
        public T[] GetComponentsInChildren<T>() where T : class => Array.Empty<T>();
        public Component[] GetComponents<Component>() => Array.Empty<Component>();
        public T AddComponent<T>() where T : Component, new() => new T();
    }

    public class Behaviour : Component
    {
        public bool enabled { get; set; } = true;
    }

    public class MonoBehaviour : Behaviour
    {
        // Unity lifecycle methods (Awake, Start, Update, OnDestroy, etc.)
        // are called via reflection, not defined on MonoBehaviour.
        // Plugin classes define these as private void methods.
    }

    public class GameObject : Object
    {
        public Transform transform { get; } = new Transform();
        public bool activeInHierarchy { get; set; } = true;
        public T GetComponent<T>() where T : class => default;
        public T GetComponentInChildren<T>() where T : class => default;
        public T[] GetComponentsInChildren<T>() where T : class => Array.Empty<T>();
        public Component[] GetComponents<Component>() => Array.Empty<Component>();
        public T AddComponent<T>() where T : Component, new() => new T();
    }

    public class Transform : Component
    {
        public Transform parent { get; set; }
        public int childCount { get; set; }
        public Transform GetChild(int index) => null;
        public Transform Find(string name) => null;
        public IEnumerator<Transform> GetEnumerator()
        {
            yield break;
        }
    }

    public static class Input
    {
        public static bool GetKeyDown(KeyCode key) => false;
        public static bool GetKey(KeyCode key) => false;
    }

    public enum KeyCode
    {
        None = 0,
        Escape = 27,
        Space = 32,
        A = 97, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z,
        LeftControl = 306, RightControl = 305,
        LeftShift = 304, RightShift = 303,
        LeftAlt = 308, RightAlt = 307
    }

    public static class Time
    {
        public static float deltaTime => 0.016f;
    }

    public static class Application
    {
        public static string dataPath => ".";
    }
}

namespace UnityEngine.UI
{
    public class Selectable : UnityEngine.Behaviour
    {
        public bool interactable { get; set; } = true;
    }

    public class Button : Selectable { }

    public class Toggle : Selectable
    {
        public bool isOn { get; set; }
    }

    public class Dropdown : Selectable
    {
        public int value { get; set; }
        public System.Collections.Generic.List<OptionData> options { get; set; }
            = new System.Collections.Generic.List<OptionData>();

        public class OptionData
        {
            public string text { get; set; } = "";
        }
    }

    public class InputField : Selectable
    {
        public string text { get; set; } = "";
        public UnityEngine.Component placeholder { get; set; }
    }

    public class Text : UnityEngine.Behaviour
    {
        public string text { get; set; } = "";
    }
}

namespace UnityEngine.EventSystems
{
    public class EventSystem
    {
        public static EventSystem current { get; } = new EventSystem();
        public UnityEngine.GameObject currentSelectedGameObject { get; set; }
    }
}

namespace UnityEngine.SceneManagement
{
    public struct Scene
    {
        public string name { get; set; }
        public void GetRootGameObjects(System.Collections.Generic.List<UnityEngine.GameObject> rootGameObjects) { }
    }

    public enum LoadSceneMode { Single, Additive }

    public static class SceneManager
    {
#pragma warning disable CS0067
        public static event System.Action<Scene, LoadSceneMode> sceneLoaded;
#pragma warning restore CS0067
        public static Scene GetActiveScene() => new Scene();
    }
}

#endif
