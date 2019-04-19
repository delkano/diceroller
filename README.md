# Dice Roller

This is a simple dice roller written as an exercise to learn Crystal.
It uses [libui.cr](https://github.com/Fusion/libui.cr) for the GUI.

## Installation



## Usage

Usage is simple. You just invoke it with

    roll

which will load the interface. You can write the roll descriptor on the text field and press the `Roll!` button to get the results.

Roll descriptors are of the form:

    expression [expression]*

    with

    expression := dice[<+|->dice]*
    dice := <number>[<a|d><number>]

Examples: 

    1d6 : Roll 1 die of 6 sides
    4d4+3 : Roll 4 dice of 4 sides each, sum the results, and add 3 to that 
    1a8 3d10: Roll 1 die of 8 sides, with explosions, then 3 dice of 10 sides, add these results, and show both rolls individually

`explosions` mean that, if the result is the maximum value for the die, it gets rolled again and the totals are added. Ex., a 6 on a 6-sided die means a new roll, which yields let's say a 3, result is 6+3=9.

## Configuration

The Dice Roller uses a config file, called `config.ini`, and stored in the `{XDG_CONFIG_HOME}/roll` directory.

This file must contain a `[general]` section, with one only entry, `model`, describing the preselected button set.

Then, it must contain at least the preselected button set, plus as many others as the user wants, in the format:

    [<name>]
    label=roll descriptor
    label 2=roll descriptor 2

This sets describe predefined roll buttons, which are shown on the UI for common rolls.

If this file becomes corrupted, simply erasing it will cause the program to create a new one, with only the "basic" button set.

## Contributing

1. Fork it (<https://github.com/your-github-user/roll/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Diego Cano](https://github.com/delkano) - creator and maintainer
