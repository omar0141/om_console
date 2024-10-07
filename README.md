![Stand With Palestine](https://raw.githubusercontent.com/TheBSD/StandWithPalestine/main/banner-no-action.svg)

# Om Console

Om Console is a live console for Flutter that enables viewing UI prints and HTTP requests. It integrates with Postman via curl for enhanced debugging capabilities.

**Note:** This package is currently in beta. While it functions well on wide screens, mobile support and the ability to copy HTTP requests as form data are still under development.

## Screenshots

<table>
  <tr>
    <td><img src="https://raw.githubusercontent.com/omar0141/om_console/refs/heads/main/Screenshot1.jpg" alt="Om Console Screenshot 1"/></td>
    <td><img src="https://raw.githubusercontent.com/omar0141/om_console/refs/heads/main/Screenshot2.png" alt="Om Console Screenshot 2"/></td>
  </tr>
  <tr>
    <td><img src="https://raw.githubusercontent.com/omar0141/om_console/refs/heads/main/Screenshot3.png" alt="Om Console Screenshot 3"/></td>
    <td><img src="https://raw.githubusercontent.com/omar0141/om_console/refs/heads/main/Screenshot4.png" alt="Om Console Screenshot 4"/></td>
  </tr>
</table>

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  om_console: ^latest_version
```

## Usage

### 1. Configure the main function

In your `main.dart` file:

```dart
import 'package:om_console/om_console.dart';

void main() async {
  Console.consoleLisitener(() {
    // Your app initialization code here
    runApp(MyApp());
  });
}
```

### 2. Wrap your MaterialApp or root widget

In your app's root widget:

```dart
import 'package:om_console/om_console.dart';

@override
Widget build(BuildContext context) {
  return Console.wrap(
    showConsole: true,
    maxLines: 200,
    child: MaterialApp(
      home: HomePage(),
      // Other MaterialApp properties
    ),
  );
}
```

### 3. Logging with tags and colors

Use the `Console.log` method for custom logging:

```dart
Console.log("Your Message or Your object", type: LogType.logs, color: Colors.amber)
```

**Note:** You don't need to replace all your prints to make them show in the console. Any app prints or logs will go by default under the normal type tab in the console. Use `Console.log` only when you want to customize the logs.

#### Available LogTypes:

- normal
- error
- logs
- http

### 4. Logging HTTP requests

For HTTP logging, use the `Console.logHttp` method:

```dart
Console.logHttp(
  url: url,
  method: "Post",
  headers: response.headers ?? {},
  body: data,
  statusCode: responseBody["status"] ?? 500,
  response: responseBody,
  textColor: Colors.black,
  backgroundColor: responseBody["status"] == 200
      ? const Color.fromARGB(255, 207, 223, 190)
      : Color.fromARGB(255, 223, 190, 190)
);
```

## Configuration

The `Console.wrap` method supports the following properties:

- `showConsole`: Boolean to toggle console visibility.
- `maxLines`: Integer to set the maximum number of rendered console lines, optimizing performance for large logs.

## Limitations and Future Improvements

- HTTP requests can only be copied as raw data. Support for copying as form data is planned for future releases.
- Search functionality in HTTP requests is still under development.

## Contributing

We welcome contributions to Om Console! Please submit issues and pull requests on our GitHub repository.
