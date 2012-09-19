require "shelly/version"

require 'readline'
require 'abbrev'

module Shelly
  # ============================
  # = Simple Command Structure =
  # ============================
  class Command
    attr_accessor :name, :description, :usage, :body
    
    def [](argstring)
      shell = Shelly::Interpreter.get_instance
      self.body[shell, argstring]
    end
  end
  
  # ===================
  # = The Interpreter =
  # ===================
  class Interpreter
    attr_accessor :prefix, :suffix, :prompt
    
    def initialize
      self.prefix = nil
      self.suffix = ''
      self.prompt = Proc.new do |c|
        "[Shelly: #{self.prefix}]#{c ? '|' : '>'} "
      end
      @commands = {}
      @exit = false
      @running = false
    end
    
    def add_command(cmd)
      command_names = @commands.keys
      if command_names.include?(cmd.name)
        raise ArgumentError.new "Already have a command named '#{cmd.name}'."
      end
      
      @commands[cmd.name] = cmd
    end
    
    def run!
      return if @running
      @running = true
      
      unless self.prefix
        raise 'Must set a prefix before running the interpreter'
      end
      
      # Setup the prompt
      if STDIN.tty?
        # Setup Readline
        Readline.completion_append_character = ''
        Readline.completion_proc = Proc.new do |str|
          completions = Dir[str+'*'].grep(/^#{Regexp.escape(str)}/)
          if completions.length == 1
            result = completions[0]
            if File.directory? result
              result += '/'
            else
              result += ' '
            end
            completions = [result]
          end
          completions
        end
        
        get_line = Proc.new do |c|
          Readline.readline(self.prompt[c], true).chomp
        end
        
        # Setup the terminal
        stty_save = `stty -g`.chomp
        cleanup = Proc.new { system('stty', stty_save) }
      else
        get_line = Proc.new { |c| STDIN.gets.chomp }
        cleanup  = Proc.new {}
      end
      
      # Set up command abbreviations
      command_names = Abbrev.abbrev(@commands.keys)
      
      # Do it!
      full_line = ''
      begin
        while (!@exit) and line = get_line[! full_line.empty?]
          full_line += line
          if full_line =~ /^(.*)\\$/
            # Line ends with a backslash, so wait for more input
            full_line = $1
            next
          elsif full_line =~ /^\\([a-z]+)\s*(.*)$/
            # Special command. Look it up and execute it
            command_name = $1
            argstring = $2
            if command_names.keys.include?(command_name)
              command = @commands[command_names[command_name]]
              command[argstring]
            else
              STDERR.puts "Unknown special command '#{command_name}'"
            end
          else
            # Run it!
            system("#{self.prefix} #{full_line} #{self.suffix}")
          end
          full_line = ''
        end
        puts 'Bye.'
      rescue
        puts # Make sure to output a newline at the end
      end
      
      cleanup[]
    end
    
    def exit!
      @exit = true
    end
    
    
    ## Turn this class into a singleton
    class <<self
      def get_instance
        @@instance
      end
    end
    @@instance = Shelly::Interpreter.new
    
    private_class_method :new
  end
  
  # =======================
  # = Convenience Methods =
  # =======================
  def command(name, opts={}, &body)
    cmd = Shelly::Command.new
    cmd.name = name
    cmd.description = opts[:description] || ''
    cmd.usage = opts[:usage] || cmd.description
    cmd.body = body
    
    Shelly::Interpreter.get_instance.add_command cmd
  end
  
  def suffix(suffix)
    Shelly::Interpreter.get_instance.suffix = suffix
  end
  
  def prompt(prompt='> ')
    if block_given?
      Shelly::Interpreter.get_instance.prompt = Proc.new
    else
      Shelly::Interpreter.get_instance.prompt = Proc.new { |c| prompt }
    end
  end
  
  def shelly(prefix)
    Shelly::Interpreter.get_instance.prefix = prefix
    Shelly::Interpreter.get_instance.run!
  end
end

# ====================
# = Default Commands =
# ====================
class Shelly::CommandContainer
  class <<self
    include Shelly
  end
  
  # ========
  # = Quit =
  # ========
  command 'quit',
      description: 'Exits the interpreter',
      usage: '\quit' do |shell, argstring|
    shell.exit!
  end
  
  # =========
  # = Shell =
  # =========
  command 'shell',
      description: 'Runs a command verbatim on your default shell',
      usage: '\shell COMMAND' do |shell, argstring|
    system(argstring.strip)
  end

  # ========
  # = Help =
  # ========
  command 'help',
      description: 'Prints a listing of available special commands or describes a specific command',
      usage: '\help [COMMAND]' do |shell, argstring|
    commands = shell.instance_eval { @commands }
    short_forms = Abbrev.abbrev(commands.keys)
  
    argstring.strip!
    if argstring.length > 0
      # Display a help message for the given command
      if short_forms.keys.include?(argstring)
        cmd = commands[short_forms[argstring]]
        puts "\\#{cmd.name}"
        puts "Aliases: #{short_forms.keys_for(cmd.name).sort.join ', '}"
        puts "Usage: #{cmd.usage}"
        puts cmd.description
      else
        STDERR.puts "Unknown command '#{argstring}'"
      end
    else
      # Show a list of commands
      puts 'Available commands:'
      commands.each_value do |cmd|
        puts " \\#{cmd.name}"
      end
    end
  end
end

# Add a convenience method to Hash
class Hash
  def keys_for(value)
    self.select { |k,v| v == value }.keys
  end
end