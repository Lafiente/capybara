# frozen_string_literal: true

module Capybara
  module Selenium
    module Find
      def find_xpath(selector, with_visibility: false, **_options)
        find_by(:xpath, selector, with_visibility: with_visibility, texts: [])
      end

      def find_css(selector, with_visibility: false, texts: [], **_options)
        find_by(:css, selector, with_visibility: with_visibility, texts: texts)
      end

    private

      def find_by(format, selector, with_visibility:, texts:)
        els = find_context.find_elements(format, selector)
        els = filter_by_text(els, texts) if (els.size > 1) && !texts.empty?
        visibilities = if with_visibility && els.size > 1
          element_visibilities(els)
        else
          []
        end
        els.map.with_index { |el, idx| build_node(el, visibilities[idx]) }
      end

      def element_visibilities(elements)
        es_context = respond_to?(:execute_script) ? self : driver
        es_context.execute_script <<~JS, elements
          return arguments[0].map(#{is_displayed_atom})
        JS
      end

      def filter_by_text(elements, texts)
        es_context = respond_to?(:execute_script) ? self : driver
        es_context.execute_script <<~JS, elements, texts
          var texts = arguments[1]
          return arguments[0].filter(function(el){
            var content = el.textContent.toLowerCase();
            return texts.every(function(txt){ return content.includes(txt.toLowerCase()) });
          })
        JS
      end

      def is_displayed_atom # rubocop:disable Naming/PredicateName
        @is_displayed_atom ||= browser.send(:bridge).send(:read_atom, 'isDisplayed')
      end
    end
  end
end
