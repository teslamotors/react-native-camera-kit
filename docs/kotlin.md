# Add Kotlin Support for Android

1. Open and edit android/build.gradle

Add the `kotlin_version` to `buildscript.ext`. If you are using React Native `0.73` or higher, you should already have a variable called `kotlinVersion` defined inside of here, so remember you can reference this instead of repeating the version number twice:

```
buildscript {
    ext {
        ...
        kotlinVersion = '1.7.20' // Variable now included for React Native core
        kotlin_version = kotlinVersion // Used by react-native-camera-kit
    }
}
```

Add `google()` to the `buildscript.repositories` and `allprojects.repositories`

```
buildscript {
    repositories {
        ...
        google()
    }
}

allprojects {
    repositories {
        ...
        google()
    }
}
```

Add the Kotlin classpath to `buildscript.dependencies`

```
dependencies {
    ...
    classpath("com.android.tools.build:gradle:7.0.2") // or recent
    classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version")
}
```

2. Open and edit android/app/build.gradle

Add Kotlin imports

```
apply plugin: "kotlin-android"
apply plugin: "kotlin-android-extensions"
```