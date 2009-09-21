# This module is only to conceal the Store class from your namespace.
#
# Example usage:
#
#   s = MonitoredItems::Store.new({:symbol => 'value', 'string' => 'other value'})
#   s.symbol   #=> 'value'
#   s.string   #=> 'other value'
module MonitoredItems
  # A Store object is much like a hash but instead of getting an setting keys you get and set instance variables.
  #
  # Example:
  #
  #   s = MonitoredItems.Store.new
  #   s.cool = true   #=> true
  #   s.silly 'not!'  #=> "not!"
  #   s.cool          #=> true
  #   s.silly         #=> "not!"
  #
  #   # OR send a hash when initializing the store
  #   i = MonitoredItems.Store.new({:cool => true})
  #   i.cool          #=> true
  class Store 
    # Supports initialization with a hash of methods & values.  It makes no difference if 
    # the keys of the hash are strings or symbols, but they are case sensitive.
    def initialize(hsh = {})
      hsh.map {|k,v| self.send(k, v)} if Hash === hsh
    end
    
    # Gets or sets instance variables based upon the methods called.
    def method_missing(mth, arg=nil)
      # append the @ symbol and remove the equal symbol (if exists):
      mth = "@#{mth}".chomp('=').to_sym
      # get or set instnace variable
      arg.nil? ? self.instance_variable_get(mth) : self.instance_variable_set(mth, arg)
    end
    
    # Return Hash representation of Store object
    def to_h
      Hash[*self.instance_variables.collect {|m| [m.slice(1..-1).to_sym, self.instance_variable_get(m)] }.flatten]
    end

    # Return inspection of hash representation of Store object
    def to_s
      self.to_h.inspect
    end
  end
end
