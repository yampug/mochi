class MultiByteComponent
  @tag_name = "multi-byte-cmp"

  def html
    %Q{
      <div class="test">
        <p>Arrows: ←, →</p>
        <p>Box: ┌─┐</p>
        <p>Emoji: 🚀✨</p>
      </div>
    }
  end

  def css
    %Q{
      .test {
        content: '│';
      }
    }
  end
end
