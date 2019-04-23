require "option_parser"
require "hedron"

require "./config"
require "./roller"

class RollerUI < Hedron::Application
    @mainwin : Hedron::Window?
    @roller: Roller?

    def initialize(config : Config)
        super()
        @config = config
        config.load
        @roller = Roller.new
    end

    def on_closing(this)
        this.destroy
        self.stop
        return false
    end

    def should_quit
        @mainwin.not_nil!.destroy
        return true
    end

    def on_set_selected(this)
        @config.switchModel @config.sets[this.selected]
        @config.save
        reloadButtonBox
    end

    def on_button_clicked(this)
        value = @config.buttonset[this.text]
        results = @roller.not_nil!.parseLine(value)
        label = results.join("\n")
        @label.not_nil!.text = label
        @entry.not_nil!.text = value
    end
    def on_roll(this)
        value = @entry.not_nil!.text
        results = @roller.not_nil!.parseLine(value)
        label = results.join("\n")
        @label.not_nil!.text = label
    end

    def draw
        self.on_stop = ->should_quit

        @mainwin = Hedron::Window.new("Dice Roller", {640, 480}, menubar: false)
        mainwin = @mainwin.not_nil!
        mainwin.margined = true
        mainwin.on_close = ->on_closing(Hedron::Window)

        @box = Hedron::VerticalBox.new
        box = @box.not_nil!
        box.padded = true
        mainwin.child = box

        hbox = Hedron::HorizontalBox.new
        hbox.padded = true
        box.push(hbox)

        @entry = Hedron::Entry.new
        entry = @entry.not_nil!
        entry.text = "Dice descriptor"
        entry.stretchy = true
        roll = Hedron::Button.new("Roll!")
        roll.on_click = -> on_roll(Hedron::Button)

        hbox.push(
            entry,
            roll
        )

        @label = Hedron::Label.new("")
        label = @label.not_nil!
        label.stretchy = true
        box.push(label)

        cbox = Hedron::Combobox.new
        cbox.choices = @config.sets
        cbox.selected = @config.sets.index(@config.model).as(Int32)
        cbox.on_select = -> on_set_selected(Hedron::Combobox)
        box.push(cbox)

        reloadButtonBox 

        mainwin.show
    end

    def reloadButtonBox
        if !@buttonbox.nil?
            @box.not_nil!.delete_at(3)
            @buttonbox.not_nil!.destroy
        end
        @buttonbox = Hedron::HorizontalBox.new
        buttonbox = @buttonbox.not_nil!

        @config.buttonset.each { |label, value| 
            button = Hedron::Button.new(label)
            button.on_click = ->on_button_clicked(Hedron::Button)
            buttonbox.push(button)
        }
        @box.not_nil!.push buttonbox
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

    ui = RollerUI.new(config)
    ui.draw
    ui.start
    ui.close
end

reloadUI
