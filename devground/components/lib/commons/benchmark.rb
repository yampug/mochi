# typed: true
require "./lib/mochi.rb"

class MochiBenchmark
  @tag_name = "mochi-benchmark"
  @rows
  @version
  @_next_id
  @_tmp

  def initialize
    @rows = []
    @version = 0
    @_next_id = 1
    @_tmp = nil
  end

  def html
    %Q{
      <div class="container">
        <div class="header">
          <h1>Mochi Benchmark</h1>
          <div class="controls">
            <button id="run" onclick="{run}">Create 1,000 rows</button>
            <button id="runlots" onclick="{run_lots}">Create 10,000 rows</button>
            <button id="add" onclick="{add}">Append 1,000 rows</button>
            <button id="update" onclick="{update}">Update every 10th row</button>
            <button id="clear" onclick="{clear}">Clear</button>
            <button id="swaprows" onclick="{swap_rows}">Swap Rows</button>
          </div>
        </div>
        <div class="test-data">
          {each @rows as row, index}
            <div class="row-item" data-testid="row">
              <span class="col-id">{item.id}</span>
              <span class="col-label"><a class="lbl" onclick="{select_row($element)}">{item.label}</a></span>
              <span class="col-remove"><a class="remove" aria-label="remove" onclick="{remove_row_by_element($element)}">&#x2715;</a></span>
            </div>
          {end}
        </div>
      </div>
    }
  end

  def css
    %Q{
      .container { max-width: 800px; margin: 0 auto; font-family: sans-serif; }
      .header { display: flex; align-items: center; justify-content: space-between; padding: 10px 0; border-bottom: 1px solid #ccc; margin-bottom: 10px; }
      h1 { margin: 0; font-size: 1.2em; }
      .controls { display: flex; flex-wrap: wrap; gap: 6px; }
      button { padding: 6px 12px; border: 1px solid #ccc; border-radius: 4px; cursor: pointer; background: #f8f9fa; font-size: 0.85em; }
      button:hover { background: #e2e6ea; }
      .row-item { display: flex; align-items: center; padding: 4px 0; border-bottom: 1px solid #f0f0f0; }
      .row-item.danger { background-color: #d9534f; color: #fff; }
      .row-item.danger a { color: #fff; }
      .col-id { width: 60px; text-align: right; padding-right: 10px; color: #666; font-size: 0.85em; }
      .col-label { flex: 1; }
      .col-label a.lbl { text-decoration: none; color: #333; cursor: pointer; }
      .col-label a.lbl:hover { text-decoration: underline; }
      .col-remove a.remove { cursor: pointer; color: #999; padding: 0 8px; text-decoration: none; }
      .col-remove a.remove:hover { color: #d9534f; }
    }
  end

  def mounted(comp)
  end

  def unmounted
  end

  def select_row(el)
    `(function(el) {
      var row = el.closest('.row-item');
      if (!row) return;
      var all = row.closest('.test-data').querySelectorAll('.row-item.danger');
      for (var i = 0; i < all.length; i++) all[i].classList.remove('danger');
      row.classList.add('danger');
    })(#{el})`
  end

  def remove_row_by_element(el)
    row = `#{el}.closest('.row-item')`
    id = `parseInt(#{row}.querySelector('.col-id').textContent)`
    remove_row(id)
  end

  def run
    @rows = make_rows(1000)
    @_next_id = @_next_id + 1000
    @version = @version + 1
  end

  def run_lots
    @rows = make_rows(10000)
    @_next_id = @_next_id + 10000
    @version = @version + 1
  end

  def add
    new_rows = make_rows(1000)
    @_next_id = @_next_id + 1000
    `(function(rows, nr) { for (var i = 0; i < nr.length; i++) rows.push(nr[i]); })(#{@rows}, #{new_rows})`
    @version = @version + 1
  end

  def update
    `(function(rows) {
      for (var i = 0; i < rows.length; i += 10)
        rows[i].label = rows[i].label + ' !!!';
    })(#{@rows})`
    @version = @version + 1
  end

  def clear
    @rows = `[]`
    @_next_id = 1
    @version = @version + 1
  end

  def swap_rows
    `(function(rows) {
      if (rows.length < 999) return;
      var tmp = rows[1]; rows[1] = rows[998]; rows[998] = tmp;
    })(#{@rows})`
    @version = @version + 1
  end

  def remove_row(id)
    `(function(rows, id) {
      var i = rows.findIndex(function(r) { return r.id === id; });
      if (i >= 0) rows.splice(i, 1);
    })(#{@rows}, #{id})`
    @version = @version + 1
  end

  private

  def make_rows(count)
    start_id = @_next_id
    `(function(self, n, sid) {
      var adj = ["pretty","large","big","small","tall","short","long","handsome","plain","quaint","clean","elegant","easy","angry","crazy","helpful","mushy","odd","unsightly","adorable","important","inexpensive","cheap","expensive","fancy"];
      var col = ["red","yellow","blue","green","pink","brown","purple","white","black","orange"];
      var noun = ["table","chair","house","bbq","desk","car","pony","cookie","sandwich","burger","pizza","mouse","keyboard"];
      var r = new Array(n);
      for (var i = 0; i < n; i++)
        r[i] = { id: sid + i, label: adj[(Math.random() * adj.length) | 0] + ' ' + col[(Math.random() * col.length) | 0] + ' ' + noun[(Math.random() * noun.length) | 0] };
      self._tmp = r;
    })(#{self}, #{count}, #{start_id})`
    @_tmp
  end
end
