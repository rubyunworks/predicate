######################################
# WARNING! Highly expiremental code! #
######################################
#
# This is an expiremntal predicate logic system for Ruby.
# The logic engine is dreafully brute-force and inefficent,
# but the main purpose of this expirment is the syntax used
# which is very clean. It would cool to see this syntax tied
# to a good backtracker or other solid logic system.
#
# See the test case below to get an understanding of its functionality.

module Predicate

  class Predicate
    attr_reader :predicate, :facts
    def initialize( name )
      @predicate = name
      @facts = []
    end
    def <<(args)
      @facts << args
    end
  end

  # Criterion is a psuedo-method probe  
  class Criterion
    attr_accessor :expression, :matches
    def initialize(exp)
      @expression = exp
      @matches = []
    end
    def match( value )
      if @expression.is_a?(Regexp)
        @matches << value if value =~ @expression
      else
        @matches << value if value == @expression
      end
    end
  end

  class Tester
    attr_reader :value
    def initialize(v)
      @value = v
    end
  end


  module LogicInclusion

    def predicate( st, *args )
      spred = ( (@predicates ||= {})[st] ||= Predicate.new(st) )
      if args.any? { |a| a.is_a?(Regexp) || a.is_a?(Criterion) }
        # every arugument is a criterion probe
        cargs = args.collect { |a| (a.is_a?(Criterion) ? a : Criterion.new(a)) }
        # update criterion matches
        spred.facts.each { |f| f.each_with_index { |a,i| cargs[i].match(a) } }
        # criterion probe
        send("#{st}_?", *cargs)
        # collect the match arrays
        nargs = cargs.collect { |c| c.matches }
        # deduce
        perms = LogicExtension.permutations(nargs)
        deductions = perms.collect { |_p|
          _t = _p.collect { |v| Tester.new(v) }
          _p if send(st,*_t)
        }.compact
        return spred.facts + deductions
      elsif args.all? { |a| a.is_a?(Tester) }
        if spred.facts.include?( args.collect { |t| t.value } )
          return true
        else
          return send("#{st}_?", *args)
        end
      else
        #puts "Defining fact #{st}(" + args.join(',') + ')'
        spred << args
      end
    end  

  end  # LogicInclusion


  module LogicExtension

    def self.permutations( arr, prepend=[] )
      head = arr[0]
      tail = arr[1..-1]
      perms = []
      if tail.empty?
        head.each { |h| perms << (prepend + [h]) }
      else
        head.each { |h| perms = perms | permutations(tail, (prepend + [h])) }
      end
      return perms
    end

    def method_added( st )
      #if st.to_s[-1..-1] != '?' && !method_defined?("#{st}_?")
      if !@prevent_method_added
        @prevent_method_added = true
        #puts "Defining predicate #{st}"
        alias_method("#{st}_?".intern, st)
        module_eval %Q{
          def #{st}(*args)
            predicate(:#{st}, *args)
          end
          def #{st}?(*args)
            targs = args.collect { |a| Tester.new(a) }
            #{st}(*targs)
          end
        }
        @prevent_method_added = false
      end
    end

  end  # LogicalExtension

end  # PredicateLogic



=begin test

  require 'test/unit'

  module TestLogic

    include Predicate::LogicInclusion
    extend Predicate::LogicExtension

    def man(x)
    end

    def woman(x)
    end

    def tool(x)
    end

    def mortal(x)
      woman(x) | man(x)
    end

    def can_use(x, y)
      ( man(x) | woman(x) ) & tool(y)
    end

  end

  class TC_Predicate < Test::Unit::TestCase

    include TestLogic

    def setup
      man('socrates')
      woman('dido')
      tool('hammer')
      can_use('me', 'ball')
    end

    def test_facts
      assert(man?('socrates'), "man?('socrates')")
      assert(woman?('dido'), "woman?('dido')")
      assert(tool?('hammer'), "tool?('hammer')")
      assert(can_use?('me', 'ball'), "can_use?('me', 'ball')")
    end

    def test_deductions
      assert(mortal?('socrates'))
      assert(mortal?('dido'))
      assert(can_use?('socrates','hammer'))
      assert(can_use?('dido','hammer'))
    end

    def test_queries
      assert(man(/.*/).include?(['socrates']))
      assert(woman(/.*/).include?(['dido']))
      assert(mortal(/.*/).include?(['socrates']))
      assert(mortal(/.*/).include?(['dido']))
      assert(can_use(/.*/,/.*/).include?(['socrates', 'hammer']))
      assert(can_use(/.*/,/.*/).include?(['dido', 'hammer']))
      assert(can_use(/.*/,/.*/).include?(['me', 'ball']))
    end

  end

=end
