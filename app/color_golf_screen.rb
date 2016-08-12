class ColorGolfScreen < UI::Screen
  def on_load
    render_view
  end

  #i've included two methods, one of them works, one of them
  #doesn't. I think its a combination of nested blocks that reference
  #a value returned by a recursive function.
  def render_view
    #do not comment out this function, the
    #`render_header`, the `works` and `doesnt_work`
    #functions rely on/depend on the calculated width from this
    #function

    render_header
    # works
    doesnt_work
  end

  def render_header
    render! :header, UI::View do end
  end

  #this approach works, if the return value from width_for is saved to
  #a private member variable, then the nested reference during button
  #creation does not cause a JNI error
  def works
    #this is a recursive function call
    @header_width = width_for(:header)

    render! :grid, UI::View do |grid|
      grid.width = @header_width
      render "button", UI::Button do |button|
        button.width = (@header_width - 30).fdiv(3)
        button.title = "test"
        button.on :tap do
          puts "booya"
        end
      end
    end
  end

  #this approach does not wor, if the return value from width_for is saved to
  #a local variable, then the nested reference during button
  #creation does causes a JNI error
  def doesnt_work
    #this is a recursive function call
    #the exception goes away if width_for_view does NOT recurse
    header_width = width_for(:header)

    render! :grid, UI::View do |grid|
      grid.width = header_width
      render "button", UI::Button do |button|
        button.width = (header_width - 30).fdiv(3)
        button.title = "test"
        #the really really insane part is the exception goes away if
        #you comment out the following block
        button.on :tap do
          puts "booya"
        end
      end
    end
  end

  def width_for id
    width_for_view(get_view(id))
  end

  #i think the issue is related to calling `width_for_view`
  #recursively. If you remove the subseqent call to width_for_view
  #(the last statment in this method), and hard code it with a value
  #(eg 300) then the exception goes away
  def width_for_view v
    @v = v

    return @v.width if !@v.width.nan?

    width_for_view(@v.parent)
  end

  def render id, klass
    previous_parent = (@current_parent || view)
    v = klass.new
    @current_parent = v
    set_view id, v
    yield v
    @current_parent = previous_parent
    @current_parent.add_child(v)
  end

  def render! id, klass, &block
    render id, klass, &block
    view.update_layout
  end

  def get_view id
    @views[id]
  end

  def set_view id, v
    @views ||= {}
    @views[id] = v
  end
end
