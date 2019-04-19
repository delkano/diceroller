require "ini"

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

