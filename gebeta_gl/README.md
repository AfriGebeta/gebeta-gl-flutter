# Flutter Gebeta GL

[![Pub Version](https://img.shields.io/pub/v/gebeta_gl)](https://pub.dev/packages/gebeta_gl)
[![likes](https://img.shields.io/pub/likes/gebeta_gl?logo=flutter)](https://pub.dev/packages/gebeta_gl)
[![Pub Points](https://img.shields.io/pub/points/gebeta_gl)](https://pub.dev/packages/gebeta_gl/score)

This Flutter plugin allows to show **embedded interactive and customizable
vector maps** as a Flutter widget.

- This project is a fork
  of [flutter-maplibre-gl](https://github.com/maplibre/flutter-maplibre-gl),
  replacing its usage of Maplibre with Gebeta libraries and extending functionality
  
This project only supports a subset of the API exposed by these libraries.

### Supported API

| Feature        | Android | iOS | Web |
|----------------|:-------:|:---:|:---:|
| Style          |    ✅    |  ✅  |  ✅  |
| Camera         |    ✅    |  ✅  |  ✅  |
| Gesture        |    ✅    |  ✅  |  ✅  |
| User Location  |    ✅    |  ✅  |  ✅  |
| Symbol         |    ✅    |  ✅  |  ✅  |
| Circle         |    ✅    |  ✅  |  ✅  |
| Line           |    ✅    |  ✅  |  ✅  |
| Fill           |    ✅    |  ✅  |  ✅  |
| Fill Extrusion |    ✅    |  ✅  |  ✅  |
| Heatmap Layer  |    ✅    |  ✅  |  ✅  |

## Get Started

#### Add as a dependency

Add `gebeta_gl` to your project by running this command:

```bash
flutter pub add gebeta_gl
```

or add it directly as a dependency to your `pubspec.yaml` file:

```yaml
dependencies:
  gebeta_gl: ^0.19.0
```

### iOS

There is no specific setup for iOS needed.


#### Use the location feature

If you access your users' location, you should also add the following key
to `ios/Runner/Info.plist` to explain why you need access to their location
data:

```xml 
<dict>
  <key>NSLocationWhenInUseUsageDescription</key>
  <string>[Your explanation here]</string>
</dict>
```

A possible explanation could be: "Shows your location on the map".

### Android

There is no specific setup for android needed to use the package.

#### Use the location feature

If you want to show the user's location on the map you need to add
the `ACCESS_COARSE_LOCATION` or `ACCESS_FINE_LOCATION` permission in the
application manifest `android/app/src/main/AndroidManifest.xml`.:

```xml
<manifest>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
</manifest>
```

Starting from Android API level 23 you also need to request it at runtime. This
plugin does not handle this for you. Our example app uses the
flutter "[location](https://pub.dev/packages/location)" plugin for this.


## Map Styles

Map styles can be supplied by setting the `styleString` in the `GebetaMap`
constructor. The following formats are supported:

1. Passing the URL of the map style. This should be a custom map style served
   remotely using a URL that start with `http(s)://`
2. Passing the style as a local asset. Create a JSON file in the `assets` and
   add a reference in `pubspec.yml`. Set the style string to the relative path
   for this asset in order to load it into the map.
3. Passing the style as a local file. create an JSON file in app directory (e.g.
   ApplicationDocumentsDirectory). Set the style string to the absolute path of
   this JSON file.
4. Passing the raw JSON of the map style. This is only supported on Android.

## Documentation

- Check
  the [API documentation](https://docs.gebeta.app).

### Avoid Android UnsatisfiedLinkError

<details>
  <summary>Click here to expand / hide.</summary>

Update buildTypes in `android\app\build.gradle`

```gradle
buildTypes {
    release {
        // other configs
        ndk {
            abiFilters 'armeabi-v7a','arm64-v8a','x86_64', 'x86'
        }
    }
}
```

---
</details>

### iOS app crashes when using location based features

<details>
  <summary>Click here to expand / hide.</summary>

Please include the `NSLocationWhenInUseUsageDescription` as
described [here](#location-features)

---
</details>

### Layer is not displayed on IOS, but no error

<details>
  <summary>Click here to expand / hide.</summary>

Have a look in your `LayerProperties` object, if you supply a `lineColor`
argument, (or any color argument) the issue might come from here.
Android supports the following format : `'rgba(192, 192, 255, 1.0)'`, but on
iOS, this doesn't work!

You have to have the color in the following format : `#C0C0FF`

---
</details>

### iOS crashes with error: `'NSInvalidArgumentException', reason: 'Invalid filter value: filter property must be a string'`

<details>
  <summary>Click here to expand / hide.</summary>

Check if one of your expression is : `["!has", "value"]`. Android support this
format, but iOS does not.
You can replace your expression with :   `["!",["has", "value"] ]` which works
both in Android and iOS.

Note : iOS will display the
error : `NSPredicate: Use of 'mgl_does:have:' as an NSExpression function is forbidden`,
but it seems like the expression still works well.

---
</details>
