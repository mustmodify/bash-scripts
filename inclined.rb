#!/usr/bin/env ruby
# frozen_string_literal: true

#
# inclined.rb - Drive a Cline agent from Ruby with file I/O
#
# Reads a prompt from a message file, sends it to Cline (with full tool access),
# and writes the agent's completion result to an output file.
#
# Usage:
#   inclined.rb -mf prompt.txt -of result.md
#   inclined.rb -mf prompt.txt -of result.md -m claude-sonnet-4-5-20250929
#   inclined.rb -mf prompt.txt  # stdout only
#
# Also usable as a library:
#   require_relative 'inclined'
#   result = Inclined.run(message_file: "prompt.txt", output_file: "result.md")
#

require "open3"
require "optparse"
require "json"

module Inclined
  VERSION = "1.0.0"

  # Run a Cline agent task.
  #
  # @param prompt [String] the prompt text (mutually exclusive with message_file)
  # @param message_file [String] path to a file containing the prompt
  # @param output_file [String, nil] path to write the result (nil = don't write)
  # @param model [String, nil] model override
  # @param cwd [String, nil] working directory for the agent
  # @param timeout [Integer, nil] timeout in seconds
  # @param json_output [Boolean] stream JSON lines instead of plain text
  # @param verbose [Boolean] verbose progress on stderr
  # @param thinking [Boolean, Integer] enable extended thinking
  # @param config [String, nil] custom cline config directory
  #
  # @return [Hash] { success: Boolean, output: String, exit_code: Integer }
  #
  def self.run(prompt: nil, message_file: nil, output_file: nil, model: nil,
               cwd: nil, timeout: nil, json_output: false, verbose: false,
               thinking: false, config: nil)

    # Resolve prompt
    text = if message_file
             raise ArgumentError, "Message file not found: #{message_file}" unless File.exist?(message_file)
             File.read(message_file)
           elsif prompt
             prompt
           else
             raise ArgumentError, "Either :prompt or :message_file must be provided"
           end

    raise ArgumentError, "Prompt is empty" if text.strip.empty?

    # Build command
    cmd = ["cline", "-y"]
    cmd += ["-m", model]           if model
    cmd += ["-c", cwd]             if cwd
    cmd += ["-t", timeout.to_s]    if timeout
    cmd << "--json"                if json_output
    cmd << "-v"                    if verbose
    if thinking
      cmd << "--thinking"
      cmd << thinking.to_s if thinking.is_a?(Integer)
    end
    cmd += ["--config", config]    if config
    cmd << text

    # Execute
    stdout, stderr, status = Open3.capture3(*cmd)

    # Write output file if requested
    if output_file
      File.write(output_file, stdout)
    end

    # Print stderr through (errors, verbose info)
    $stderr.print(stderr) unless stderr.empty?

    {
      success: status.success?,
      output: stdout,
      exit_code: status.exitstatus
    }
  end
end

# CLI entry point (only when run directly, not when required as a library)
if __FILE__ == $PROGRAM_NAME
  options = {}

  parser = OptionParser.new do |opts|
    opts.banner = "Usage: inclined.rb [options]"
    opts.separator ""
    opts.separator "Drive a Cline agent with file I/O."
    opts.separator ""

    opts.on("-mf", "--message-file FILE", "File containing the prompt") do |f|
      options[:message_file] = f
    end

    opts.on("-of", "--output-file FILE", "File to write result to") do |f|
      options[:output_file] = f
    end

    opts.on("-m", "--model MODEL", "Model override") do |m|
      options[:model] = m
    end

    opts.on("-c", "--cwd PATH", "Working directory for the agent") do |c|
      options[:cwd] = c
    end

    opts.on("-t", "--timeout SECONDS", Integer, "Timeout in seconds") do |t|
      options[:timeout] = t
    end

    opts.on("--json", "Output JSON lines") do
      options[:json_output] = true
    end

    opts.on("-v", "--verbose", "Verbose output on stderr") do
      options[:verbose] = true
    end

    opts.on("--thinking [TOKENS]", "Enable extended thinking") do |t|
      options[:thinking] = t ? t.to_i : true
    end

    opts.on("--config PATH", "Custom cline config directory") do |c|
      options[:config] = c
    end

    opts.on("--dry-run", "Show the command that would be run") do
      options[:dry_run] = true
    end

    opts.on("-h", "--help", "Show this help") do
      puts opts
      exit
    end

    opts.on("--version", "Show version") do
      puts "inclined.rb #{Inclined::VERSION}"
      exit
    end
  end

  # Pre-process args: expand -mf/-of to long forms (OptionParser doesn't do multi-char short opts)
  expanded_argv = ARGV.map do |arg|
    case arg
    when "-mf" then "--message-file"
    when "-of" then "--output-file"
    else arg
    end
  end
  parser.parse!(expanded_argv)

  # Validate input
  unless options[:message_file] || !$stdin.tty?
    $stderr.puts "Error: No message file (-mf) provided and stdin is not piped."
    $stderr.puts parser.to_s
    exit 1
  end

  # Read from stdin if no message file
  unless options[:message_file]
    options[:prompt] = $stdin.read
  end

  if options[:dry_run]
    # Build and show the command without executing
    text = options[:message_file] ? File.read(options[:message_file]).chomp : options[:prompt]&.chomp
    cmd = ["cline", "-y"]
    cmd += ["-m", options[:model]]      if options[:model]
    cmd += ["-c", options[:cwd]]        if options[:cwd]
    cmd += ["-t", options[:timeout].to_s] if options[:timeout]
    cmd << "--json"                     if options[:json_output]
    cmd << "-v"                         if options[:verbose]
    cmd << "--thinking"                 if options[:thinking]
    cmd += ["--config", options[:config]] if options[:config]
    cmd << text
    puts "Would run:"
    puts cmd.map { |c| c.include?(" ") || c.include?("\n") ? c.inspect : c }.join(" ")
    exit 0
  end

  result = Inclined.run(**options.slice(:prompt, :message_file, :output_file, :model,
                                        :cwd, :timeout, :json_output, :verbose,
                                        :thinking, :config))

  # Print to stdout (unless output_file was specified, in which case it's already written)
  print result[:output] unless options[:output_file]

  exit(result[:success] ? 0 : 1)
end
