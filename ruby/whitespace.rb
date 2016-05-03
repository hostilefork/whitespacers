#!/usr/bin/ruby

# whitepsace-ruby
# Copyright (C) 2003 by Wayne E. Conrad
# 
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
# 
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
# 
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA

Opcodes = [
  ['  ', :push, :signed],
  [' \n ', :dup],
  [' \n\t', :swap],
  [' \n\n', :discard],
  [' \t ', :copy, :signed],
  [' \t\n', :slide, :signed],
  ['\t   ', :add], 
  ['\t  \t', :sub],
  ['\t  \n', :mul],
  ['\t \t ', :div],
  ['\t \t\t', :mod],
  ['\t\t ', :store],
  ['\t\t\t', :retrieve],
  ['\n  ', :label, :unsigned],
  ['\n \t', :call, :unsigned],
  ['\n \n', :jump, :unsigned],
  ['\n\t ', :jz, :unsigned],
  ['\n\t\t', :jn, :unsigned],
  ['\n\t\n', :ret],
  ['\n\n\n', :exit],
  ['\t\n  ', :outchar],
  ['\t\n \t', :outnum],
  ['\t\n\t ', :readchar],
  ['\t\n\t\t', :readnum],
]

def error(message)
  $stderr.puts "Error: #{message}"
  exit 1
end

class Tokenizer

  attr_reader :tokens

  def initialize
    @tokens = []
    @program = $<.read.tr("^ \t\n", "")
    while @program != "" do
      @tokens << tokenize
    end
  end

  private

  def tokenize
    for ws, opcode, arg in Opcodes
      if /\A#{ws}#{arg ? '([ \t]*)\n' : '()'}(.*)\z/m =~ @program
        @program = $2
        case arg
        when :unsigned
          return [opcode, eval("0b#{$1.tr(" \t", "01")}")]
        when :signed
          value = eval("0b#{$1[1..-1].tr(" \t", "01")}")
          value *= -1 if ($1[0] == ?\t)
          return [opcode, value]
        else
          return [opcode]
        end
      end
    end
    error("Unknown command: #{@program.inspect}")
  end

end

class Executor

  def initialize(tokens)
    @tokens = tokens
  end

  def run
    @pc = 0
    @stack = []
    @heap = {}
    @callStack = []
    loop do
      opcode, arg = @tokens[@pc]
      @pc += 1
      case opcode
      when :push
        @stack.push arg
      when :label
      when :dup
        @stack.push @stack[-1]
      when :outnum
        print @stack.pop
      when :outchar
        print @stack.pop.chr("UTF-8")
      when :add
        binaryOp("+")
      when :sub
        binaryOp("-")
      when :mul
        binaryOp("*")
      when :div
        binaryOp("/")
      when :mod
        binaryOp("%")
      when :jz
        jump(arg) if @stack.pop == 0
      when :jn
        jump(arg) if @stack.pop < 0
      when :jump
        jump(arg)
      when :discard
        @stack.pop
      when :exit
        exit
      when :store
        value = @stack.pop
        address = @stack.pop
        @heap[address] = value
      when :call
        @callStack.push(@pc)
        jump(arg)
      when :retrieve
        @stack.push @heap[@stack.pop]
      when :ret
        @pc = @callStack.pop
      when :readchar
        @heap[@stack.pop] = $stdin.getc.each_codepoint.next
      when :readnum
        @heap[@stack.pop] = $stdin.gets.to_i
      when :swap
        @stack[-1], @stack[-2] = @stack[-2], @stack[-1]
      when :copy
        @stack.push @stack[-arg-1]
      when :slide
        @stack.slice!(-arg-1, arg)
      else
        error("Unknown opcode: #{opcode.inspect}")
      end
    end
  end

  private

  def binaryOp(op)
    b = @stack.pop
    a = @stack.pop
    @stack.push eval("a #{op} b")
  end

  def jump(label)
    @tokens.each_with_index do |token, i| 
      if token == [:label, label]
        @pc = i
        return
      end
    end
    error("Unknown label: #{label}")
  end

end

Executor.new(Tokenizer.new.tokens).run
