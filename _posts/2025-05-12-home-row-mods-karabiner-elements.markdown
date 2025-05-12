---
layout: post
title: "Configuring Home Row Mods with Karabiner-Elements"
date: 2025-05-12 02:00:00
tags: keyboard
---

This note shows how I’ve configured
[home row mods (HRM)](https://precondition.github.io/home-row-mods) with
[Karabiner-Elements (KE)](https://karabiner-elements.pqrs.org/).
I developed this configuration to address shortcomings solutions I’ve found
on Internet, e.g., this configuration never loses key presses.
It turns out, it is suprisingly non-trivial to implement such a popular mod
as HRM.

## Configuration

Here’s a snippet of the approach for configuring “a” as
Ctrl and “s” as Command:

```json5
{
  "description": "Home row mods (as) - control, command",
  "manipulators": [
    {
      // If I press "a" and "s"…
      "from": {
        // With any modifier…
        "modifiers": { "optional": ["any"] },
        "simultaneous": [{ "key_code": "a" }, { "key_code": "s" }],
        "simultaneous_options": { "key_down_order": "strict" }
      },
      // … and press something else quickly, then just output "a" and "s".
      "to_delayed_action": {
        "to_if_canceled": [{ "key_code": "a" }, { "key_code": "s" }],
        "to_if_invoked": [{ "key_code": "vk_none" }]
      },
      // … and release, then just output "a" and "s".
      "to_if_alone": [
        {
          // Do not run the delayed action. We are committed.
          "halt": true,
          "key_code": "a"
        },
        { "key_code": "s" }
      ],
      // … and hold, then just treat it as a modifier.
      "to_if_held_down": [
        {
          // Do not run the delayed action. We are committed.
          "halt": true,
          "key_code": "left_control",
          "modifiers": ["left_command"]
        }
      ],
      "type": "basic"
    },
    // Cover the case of pressing `sa`.
    {
      "from": {
        "modifiers": { "optional": ["any"] },
        "simultaneous": [{ "key_code": "s" }, { "key_code": "a" }],
        "simultaneous_options": { "key_down_order": "strict" }
      },
      "to_delayed_action": {
        "to_if_canceled": [{ "key_code": "s" }, { "key_code": "a" }],
        "to_if_invoked": [{ "key_code": "vk_none" }]
      },
      "to_if_alone": [
        {
          "halt": true,
          "key_code": "s"
        },
        { "key_code": "a" }
      ],
      "to_if_held_down": [
        {
          "halt": true,
          "key_code": "left_control",
          "modifiers": ["left_command"]
        }
      ],
      "type": "basic"
    },
    {
      "from": {
        "key_code": "a",
        "modifiers": { "optional": ["any"] }
      },
      "to_if_alone": [
        {
          "halt": true,
          "key_code": "a"
        }
      ],
      "to_if_held_down": [
        {
          "halt": true,
          "key_code": "left_control"
        }
      ],
      // If another key is pressed, while doing a combo with "a", just output
      // "a".
      "to_delayed_action": {
        "to_if_canceled": [{ "key_code": "a" }],
        "to_if_invoked": [{ "key_code": "vk_none" }]
      },
      "type": "basic"
    },
    {
      "from": {
        "key_code": "s",
        "modifiers": { "optional": ["any"] }
      },
      "to_if_alone": [
        {
          "halt": true,
          "key_code": "s"
        }
      ],
      "to_if_held_down": [
        {
          "halt": true,
          "key_code": "left_command"
        }
      ],
      "to_delayed_action": {
        "to_if_canceled": [{ "key_code": "s" }],
        "to_if_invoked": [{ "key_code": "vk_none" }]
      },
      "type": "basic"
    }
  ]
}
```

I use this config with the following parameters:

- `to_if_alone_timeout_milliseconds`: 400
- `to_if_held_down_threshold_milliseconds`: 110
- `simultaneous_threshold_milliseconds`: 90

## Why so complex?

One reason why this configuration is so complex is that KE doesn’t let us define
HRM in the form of: “if ‘a’ is held, then it’s left control”.
The biggest obstacle is that if you have a manipulator for “a”, then
pressing “a,” and then “s” before the `if_held` action triggers, the
a-manipulator cancels, and we get nothing.
We need to work with manipulators for simultaneous key presses, and we need to
define them for every combination that we might encounter.
We also need to work with delayed actions to cover the case when a non-home row
key gets pressed while a home row key is held.

## Limitations

One limitation is that you can’t dynamically remove modifiers.
For example, if you hold “as” for Ctrl-Command and release “s,”
then you just lost both modifiers, not just Command.
