module Kernel
  # Duplicate an object if it can be duplicated.  If it can not be
  # cloned or duplicated, then just return the original object.
  def rake_dup()
    dup
  end
end

[NilClass, FalseClass, TrueClass, Fixnum, Symbol].each do |clazz|
  clazz.class_eval {
    # Duplicate an object if it can be duplicated.  If it can not be
    # cloned or duplicated, then just return the original object.
    def rake_dup() self end
  }
end


######################################################################
# Rake extensions to Module.
#
class Module

  # Check for an existing method in the current class before
  # extending.  IF the method already exists, then a warning is
  # printed and the extension is not added.  Otherwise the block is
  # yielded and any definitions in the block will take effect.
  #
  # Usage:
  #
  #   class String
  #     rake_extension("xyz") do
  #       def xyz
  #         ...
  #       end
  #     end
  #   end
  #
  def rake_extension(method)
    if instance_methods.include?(method)
      $stderr.puts "WARNING: Possible conflict with Rake extension: #{self}##{method} already exists"
    else
      yield
    end
  end
end


######################################################################
# User defined methods to be added to String.
#
class String
  rake_extension("ext") do
    # Replace the file extension with +newext+.  If there is no
    # extenson on the string, append the new extension to the end.  If
    # the new extension is not given, or is the empty string, remove
    # any existing extension.
    #
    # +ext+ is a user added method for the String class.
    def ext(newext='')
      return self.dup if ['.', '..'].include? self
      if newext != ''
        newext = (newext =~ /^\./) ? newext : ("." + newext)
      end
      dup.sub!(%r(([^/\\])\.[^./\\]*$)) { $1 + newext } || self + newext
    end
  end

  rake_extension("pathmap") do
    # Explode a path into individual components.  Used by +pathmap+.
    def pathmap_explode
      head, tail = File.split(self)
      return [self] if head == self
      return [tail] if head == '.' || tail == '/'
      return [head, tail] if head == '/'
      return head.pathmap_explode + [tail]
    end
    protected :pathmap_explode

    # Extract a partial path from the path.  Include +n+ directories
    # from the front end (left hand side) if +n+ is positive.  Include
    # |+n+| directories from the back end (right hand side) if +n+ is
    # negative.
    def pathmap_partial(n)
      target = File.dirname(self)
      dirs = target.pathmap_explode
      if n > 0
        File.join(dirs[0...n])
      elsif n < 0
        partial = dirs[n..-1]
        if partial.nil? || partial.empty?
          target
        else
          File.join(partial)
        end
      else
        "."
      end
    end
    protected :pathmap_partial

  end
end