require 'matrix'

class Env < Hash
  #attr_accessor :outer
  #@outer
  
  def initialize(params, args, outer=nil)
    args = args[0]
     params.count.times do |i|
      self[params[i]] = args[i]
    end
    self.merge!(outer)
  #  self.outer = outer
  end
  #def find(var)
  #  if (self[var])
  #    puts self[var]
  #    return self[var]
  #  else
  #    self.outer.find(var)
  #  end
  #end
end

def tokenize (string)
  string.gsub('[', ' [ ').gsub(']', ' ] ').split.to_a
end
def atomize(token)
  Float(token) rescue token.to_sym
end
def read_from(tokens)
  unless tokens.length == 0
    #take off first eleenet
    token = tokens.shift
    if token == "["
      array = []
      while (tokens[0] != ']')
        #recursively call for in between brackets
        result = read_from(tokens)
        array << result
      end
      tokens.shift
      return array
    else
      if token == ']'
        raise ('unexpected ]')
      else
        #return single elements
        return atomize(token)
      end
    end
  else
    raise ('unexpected EOF')
  end
end

def evaluate (tokens, env)
  #literals
  if tokens.kind_of? Symbol
    puts tokens.to_s + "symbol"
    return env[tokens]
  elsif tokens.kind_of? Float
    puts tokens.to_s + "float"
    return tokens
  elsif tokens.kind_of? Vector
    puts tokens.to_s + "vector"
    return tokens
  #conditionals
  elsif tokens[0] == :if
    puts tokens.to_s + "conditional"
    test = tokens[1]
    conseq = tokens[2]
    alt = tokens[3]
    if (evaluate test, env) != 0
      evaluate conseq, env
    else
      evaluate alt, env
    end
  #define
  elsif tokens[0] == :define
    puts tokens.to_s + "def"
    var = tokens[1]
    result = evaluate tokens[2], env
    env[var] = result
  #begin statement block
  elsif tokens[0] == :begin
    puts tokens.to_s + "begin"
    tokens[1..-1].each do |expression|
      var = evaluate expression, env
    end
    return var
  #define a function
  elsif tokens[0] == :function
    puts tokens.to_s + "function def"
    vars = tokens[1]
    expression = tokens[2]
    return lambda {|*args| evaluate(expression, Env.new(vars, args, env))}
  #call as in [function args args args...]
  else
    puts tokens.to_s + "function call"
    tokens = tokens.collect do |expression|
      evaluate expression, env
    end
    function = tokens.shift
    if tokens.count == 1
      return function.call(tokens[0])
    else
      return function.call(tokens)
    end
  end
end

def read (input)
  current_position = Vector[0,0,0]
  global_env = Hash[:+ => Proc.new{|a,b| a+b},
                    :- => Proc.new{|a,b| a-b},
                    :* => Proc.new{|a,b| a*b},
                    :/ => Proc.new{|a,b| a/b},

                    :~ => Proc.new{|a,b,c| Vector.elements([a,b,c], true)},
                    :dot => Proc.new{|a,b| a.inner_product(b)},
                    :norm => Proc.new{|a| a.norm},
                    :nmlz => Proc.new{|a| a.normalize},

                    :curr_pos => current_position,
                    :move => Proc.new{|a| current_position = current_position + a},
                    :return_to => Proc.new{|a| current_position = a},
                    :point_down => Proc.new{|| puts current_position}
                    ]
  tokens = tokenize(input)
  evaluate(read_from(tokens), global_env)
end

def repl
  rep = true
  while rep
    '> '.display
    e = gets.chomp!
    if e == "quit"
      rep = false
    else
      puts(read(e))
    end
  end
end

repl()