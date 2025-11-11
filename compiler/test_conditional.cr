require "./src/html/conditional_processor"

# Test example HTML like it would appear in a Mochi component
html = %Q{
  <div class="wrapper">
    <h1>Count: {count}</h1>
    {if @count > 5}
      <p>Count is greater than 5!</p>
      {if @count > 10}
        <p>Count is even greater than 10!</p>
      {end}
    {end}
    <button on:click={increment}>Increment</button>
  </div>
}

puts "Original HTML:"
puts html
puts "\n" + "="*80 + "\n"

result = ConditionalProcessor.process(html)

puts "Processed HTML:"
puts result.html
puts "\n" + "="*80 + "\n"

puts "Extracted Conditionals:"
result.conditionals.each_with_index do |cond, i|
  puts "  #{i + 1}. Condition: '#{cond.condition}'"
  puts "     Content: #{cond.content[0...50]}..."
  puts ""
end
