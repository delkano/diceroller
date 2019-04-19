require "option_parser"
require "libui/libui"

require "./config"
require "./roller"

class RollerUI
    # Copied from examples
    def initialize(config : Config) #, @arg : Array(String))
        @@config = config
        @@config.as(Config).load

        o = UI::InitOptions.new
        err = UI.init pointerof(o)
        if !ui_nil?(err)
            puts "error initializing ui: #{err}"
            exit 1
        end

        on_closing = ->(w : UI::Window*, data : Void*) {
            UI.control_destroy ui_control(@@mainwin.not_nil!)
            UI.quit
            @@config.as(Config).save
            0
        }

        should_quit = ->(data : Void*) {
            UI.control_destroy ui_control(@@mainwin.not_nil!)
            1
        }

        # mine
        @@roller = Roller.new

        on_button_clicked = ->(s : UI::Button*, data : Void*) {
            line = String.new(UI.entry_text @@entry)

            roller = @@roller.as(Roller)
            res = roller.parseLine(line)

            label = res.join("\n")

            UI.label_set_text @@results, label
        }
        on_set_selected = ->(s : UI::Combobox*, data : Void*) {
            conf = @@config.as(Config)
            i = UI.combobox_selected @@buttonselector
            sets = conf.sets
            conf.switchModel sets[i]
            conf.save

            #UI.control_destroy(@@buttons.as(Pointer(UI::Control)))
            UI.box_delete(@@box, 3)
            @@buttons = RollerUI.createButtonBox(@@box).as(UI::Box*)
        }

        # UI describing
        @@mainwin = UI.new_window "Dice Roller", 640, 480, 0
        mainwin = @@mainwin.not_nil!
        UI.window_set_margined mainwin, 1
        UI.window_on_closing mainwin, on_closing, nil

        @@box = UI.new_vertical_box
        box = @@box.not_nil!
        UI.box_set_padded box, 1
        UI.window_set_child mainwin, ui_control(box)

        hbox = UI.new_horizontal_box
        UI.box_set_padded hbox, 1
        UI.box_append box, ui_control(hbox), 1

        @@entry = UI.new_entry()
        entry = @@entry.not_nil!
        #line = ""
        #if @arg.size == 0
        line = "Dice descriptor"
        #else
        #    @arg.each{ |arg| line += arg+" "}
        #end
        UI.entry_set_text entry, line
        button = UI.new_button("Roll!")
        UI.box_append hbox, ui_control(entry), 0
        UI.button_on_clicked button, on_button_clicked, nil
        UI.box_append hbox, ui_control(button), 1

        @@results = UI.new_label("")
        results = @@results.not_nil!
        UI.box_append box, ui_control(results), 1

        # Custom button set selector
        @@buttonselector = UI.new_combobox
        buttonselector = @@buttonselector.not_nil!
        i = 0
        @@config.as(Config).sets.each {|label|
            UI.combobox_append buttonselector, label
            if label == @@config.as(Config).model
                UI.combobox_set_selected buttonselector, i
            end
            i+=1
        }
        UI.combobox_on_selected buttonselector, on_set_selected, nil
        UI.box_append box, ui_control(buttonselector), 1

        @@buttons = RollerUI.createButtonBox(box).as(UI::Box*)
        # UI described

        #ends mine

        UI.control_show ui_control(mainwin)

        UI.main
        UI.uninit
    end

    def self.createButtonBox(box : UI::Box*|Nil) : UI::Box*
        on_custom_clicked = ->(s : UI::Button*, data : Void*) {
            buttons = @@config.as(Config).buttonset
            value = buttons[String.new(UI.button_text(s))]

            roller = @@roller.as(Roller)
            res = roller.parseLine(value)

            label = res.join("\n")

            UI.entry_set_text @@entry, value
            UI.label_set_text @@results, label
        }

        # Custom, config-loaded buttons
        buttonbox = UI.new_horizontal_box
        UI.box_set_padded buttonbox, 1
        UI.box_append box, ui_control(buttonbox), 1
        @@config.as(Config).buttonset.each {|label, value| 
            button = UI.new_button(label)
            UI.button_on_clicked button, on_custom_clicked, value
            UI.box_append buttonbox, ui_control(button), 1
        }

        return buttonbox
    end
end

XDG_CONFIG_HOME        = ENV.fetch("XDG_CONFIG_HOME", "~/.config")
CONFIG_HOME            = File.expand_path "#{XDG_CONFIG_HOME}/roll"
if !Dir.exists? CONFIG_HOME
    Dir.mkdir CONFIG_HOME
end

def reloadUI
    configfile = CONFIG_HOME+"/config.ini"

    OptionParser.parse! do |parser|
        parser.banner = "Usage: roll [options]"
        parser.on("-c FILENAME", "--config=FILENAME", "Specifies the config filename") { |filename| configfile = filename }
        parser.on("-h", "--help", "Show this help") { puts parser; exit }
        parser.invalid_option do |flag|
            STDERR.puts "ERROR: #{flag} is not a valid option."
            STDERR.puts parser
            exit(1)
        end
    end

    config = Config.new(configfile)

    RollerUI.new(config)
end

reloadUI
