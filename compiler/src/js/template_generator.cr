module JS
  class TemplateGenerator
    def self.generate_registry : String
      <<-JS
      const _mochi_templates = {};
      JS
    end

    def self.generate_component(component_name : String, template_id : String, static_html : String) : String
      <<-JS
      _mochi_templates['#{template_id}'] = document.createElement('template');
      _mochi_templates['#{template_id}'].innerHTML = #{static_html.inspect};

      class #{component_name} extends MochiComponent {
        mount(target) {
          const root = _mochi_templates['#{template_id}'].content.cloneNode(true);
          target.appendChild(root);
        }
      }
      JS
    end
  end
end
