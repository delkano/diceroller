require "option_parser"
require "ini"
require "libui/libui"

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
        on_custom_clicked = ->(s : UI::Button*, data : Void*) {
            buttons = @@config.as(Config).buttonset
            value = buttons[String.new(UI.button_text(s))]

            roller = @@roller.as(Roller)
            res = roller.parseLine(value)

            label = res.join("\n")

            UI.entry_set_text @@entry, value
            UI.label_set_text @@results, label
        }
        on_set_selected = ->(s : UI::Combobox*, data : Void*) {
            conf = @@config.as(Config)
            i = UI.combobox_selected @@buttonselector
            sets = conf.sets
            conf.switchModel sets[i]
            conf.save
            UI.control_destroy ui_control(@@mainwin.not_nil!)
            reloadUI
        }

        # UI describing
        @@mainwin = UI.new_window "Dice Roller", 640, 480, 0
        mainwin = @@mainwin.not_nil!
        UI.window_set_margined mainwin, 1
        UI.window_on_closing mainwin, on_closing, nil

        box = UI.new_vertical_box
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

        # Custom, config-loaded buttons
        buttonbox = UI.new_horizontal_box
        UI.box_set_padded buttonbox, 1
        UI.box_append box, ui_control(buttonbox), 1
        @@config.as(Config).buttonset.each {|label, value| 
            button = UI.new_button(label)
            UI.button_on_clicked button, on_custom_clicked, value
            UI.box_append buttonbox, ui_control(button), 1
        }
        
        # UI described

        #ends mine

        UI.control_show ui_control(mainwin)

        UI.main
        UI.uninit
    end
end

class Roller
    # parses a line of text describing one or more dice rolls
    # returns an array of strings, each the relevant arg, a period, and the result
    def parseLine(line)
        begin
            ret = [] of String
            if line
                line.split { |roll|
                    res = self.parseRoll roll
                    ret.push roll+": "+res.to_s
                }
            end
            return ret
        rescue
            return ["Error: Bad roll descriptor"]
        end
    end

    # parses a dice descriptor string
    def parseRoll(line)
        total = 0
        if line
            line.split("+") { |part| 
                parts = part.split("-")
                head = parts.shift
                total += self.parseDie head
                parts.each { |die| 
                    total -= self.parseDie die
                }
            }
        end
        return total
    end

    # parses a one die type string
    def parseDie(line)
        explodes = line.includes? "a"
        letter = explodes ? /a|A/ : /d|D/
        parts = line.split(letter)
        return line.to_i if parts.size == 1
        type = parts[1].to_i
        total = 0;
        parts[0].to_i.times {
            roll = 1+rand(type)
            total += roll
            if explodes 
                while roll == type
                    roll = 1+rand(type)
                    total += roll
                end
            end
        }
        return total
    end

end

class Config 
    property filename : String
    property conf : Hash(String, Hash(String,String))
    getter buttonset : Hash(String, String)
    getter model : String
    
    def initialize(filename : String)
        @filename = filename

        default = {
            "general" => {
                "model" => "basic"
            },
            "basic" => {
                "d4" => "1d4",
                "d6" => "1d6",
                "d8" => "1d8",
                "d10" => "1d10",
                "d12" => "1d12",
                "d20" => "1d20"
            }
        }
        @conf = default
        @model = "basic"
        @buttonset = @conf[@model]
    end

    def load
        if File.exists? @filename
            content = File.read(@filename)
            @conf = INI.parse(content)

            if @conf["general"]["model"]
                @model = @conf["general"]["model"]
            else
                @model = "basic"
            end
            @buttonset = @conf[@model]
        end
    end

    def sets
        keys = @conf.keys
        keys.shift
        return keys
    end

    def switchModel(name : String)
        @model = name
        @buttonset = @conf[@model]
    end

    def save
        @conf["general"]["model"] = @model
        content = INI.build @conf
        File.write(@filename, content)
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
