# DragList

[![pub package](https://img.shields.io/pub/v/drag_list.svg)](https://pub.dartlang.org/packages/drag_list)

Flutter list widget that allows to drag and drop items and define custom drag handle widget.

![DragList demo](https://giant.gfycat.com/BraveElegantDarklingbeetle.gif)

## Getting Started

Add `DragList` component to your widget tree:

```Dart
child: DragList<String>(
  items: ['Tuna', 'Meat', 'Cheese', 'Potato', 'Eggs', 'Bread'],
  itemExtent: 72.0,
  builder: (context, item, handle) {
    return Container(
      height: 72.0,
      child: Row(children: [
        Spacer(),
        Text(item),
        Spacer(),
        handle,
      ]),
    );
  },
),
```

Optionally, provide custom handle builder:

```Dart
child: DragList<String>(
  // ...
  handleBuilder: (context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Container(
        color: Colors.green,
        child: Text('Handle'),
      ),
    );
  },
),
```

Add other optional parameter if needed:

```Dart
child: DragList<String>(
  // ...
  animDuration: Duration(milliseconds: 500),
  dragDelay: Duration(seconds: 1),
  handleAlignment: -0.3,
  scrollDirection: Axis.horizontal,
  onItemReorder: (from, to) {
    // handle item reorder on your own
  },
),
```

Use `handleless` constructor if you want list item to be dragged no matter where it's tapped on:

```Dart
DragList<String>.handleless(
  // ...
  builder: (context, item) {
    return Container(
      height: 72.0,
      child: Center(child: Text(item)),
    );
  },
),
```
