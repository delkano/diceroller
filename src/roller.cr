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

