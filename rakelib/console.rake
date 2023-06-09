module Console
  # ANSI colors
  RED = 1
  GREEN = 2
  YELLOW = 3
  PURPLE = 4

  def self.color_puts(lines, color_code:)
    puts "\x1b[3#{color_code}m#{lines}\x1b[0m"
  end

  def self.header(title)
    color_puts(">>> #{title}", color_code: GREEN) # green
  end

  def self.info(text)
    color_puts(text, color_code: YELLOW) # yellow
  end

  def self.warning(text)
    color_puts(title, color_code: RED) # red
  end

  def self.print_indented_lines(lines)
    color_puts(lines.map { |l| "| #{l}" }.join, color_code: YELLOW)
  end

  def self.prompt(text, default_value)
    color_puts("#{text}? [default: #{default_value}] ", color_code: GREEN)
    answer = $stdin.gets.chomp
    answer = default_value if answer.empty?
    answer
  end

  def self.confirm(text)
    color_puts("#{text} [y/n]?", color_code: GREEN)
    answer = $stdin.gets.chomp
    answer.downcase == 'y'
  end
end
