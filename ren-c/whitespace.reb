Rebol [
    Title: "Whitespace Intepreter"
    Purpose: "Whitespace Language Written as a Rebol 3 Parse Dialect"

    Author: "Hostile Fork"
    Home: http://github.com/hostilefork/whitespacers/
    License: 'mit

    File: %whitespace.r
    Date: 10-Jul-2010
    Version: 0.2.0

    ; Header conventions: http://www.rebol.org/one-click-submission-help.r
    Type: 'fun
    Level: 'intermediate

    Description: {
        This is an interpreter for the Whitespace language:

        http://compsoc.dur.ac.uk/whitespace/
    }

    Usage: {
        Run it.  Program is currently hardcoded into a variable, but
        I'll change it to take command line parameters.  Also, I should
        add a switch to generate documentation.
    }

    History: [
        0.1.0 [8-Oct-2009 {Private release to R3 Chat Group for commentary}]

        0.2.0 [10-Jul-2010 {Public release as part of a collection of
        whitespace interpreters in various languages}]
    ]
]

;
; WHITESPACER IMPLEMENTATION DIALECT
;
; Our goal is to streamline the implementation by bending Ren-C into something
; that feels like *a programming language designed specially for writing
; whitespace implementations*.  This methodology for putting the parts of the
; language to new uses is called "dialecting".
;

category: func [
    return: [object!]
    definition [block!]
    <local> obj
][
    ; We want the category to create an object, but we don't want the fields of
    ; the object to be binding inside the function bodies defined in the
    ; category.  e.g. just because the category has an ADD operation, we don't
    ; want to overwrite the binding of Rebol's ADD which we would use.
    ;
    ; !!! This is part of a broad current open design question, being actively
    ; thought through:
    ;
    ; https://forum.rebol.info/t/1442
    ;
    ; It should have a turnkey solution like what this code is doing.  We just
    ; don't know exactly what to call it.

    ; First make an empty object with all the SET-WORD!s at the top level
    ;
    obj: make object! collect [
        for-each item definition [
            keep match set-word! item
        ]
        keep ['~unset~]
    ]

    ; Now, run a block which is a copy where all the SET-WORD!s are bound
    ; into the object, but only those top level set-words...nothing else.
    ;
    do map-each item definition [
        (in obj try match set-word! item) else [item]
    ]

    return obj
]

operation: enfixed func [
    return: [object!]
    'name [set-word!]
    spec [block!]
    action [action!]
][
    ; We want the operation to be a function (and be able to bind to it as
    ; if it is one).  But there's additional information we want to glue on.
    ; Historical Rebol doesn't have the facility to add data fields to
    ; functions as if they were objects (like JavaScript can).  But Ren-C
    ; offers a connected "meta" object.  We could make `some-func.field`
    ; notation access the associated meta fields, though this would be
    ; an inconsistent syntax.
    ;
    ; Temporarily just return an object, but name the action inside it the
    ; same thing as what we capture from the callsite as the SET-WORD!.
    ;
    ; Note: Since this operation is quoting the SET-WORD! on the left, the
    ; evaluator isn't doing an assignment.  We have to do the SET here.
    ;
    set name make object! compose [
        description: ensure text! first spec
        command: copy next spec  ; TBD: validation

        (name) '(:action)  ; for `push: operation ...` this will be `push/push`
    ]
]


;
; CONTROL SEQUENCE DEFINITIONS
;
;     http://compsoc.dur.ac.uk/whitespace/tutorial.php
;

Stack-Manipulation: category [
    IMP: [space]

    description: {
        Stack manipulation is one of the more common operations, hence the
        shortness of the IMP [space].
    }

    push: operation [
        {Push the number onto the stack}
        space Number
    ] func [value [integer!]] [
        insert stack value
        return null
    ]

    duplicate-top: operation [
        {Duplicate the top item on the stack}
        lf space
    ] func [] [
        insert stack first stack
        return null
    ]

    duplicate-indexed: operation [
        {Copy Nth item on the stack (given by the arg) to top of stack}
        tab space Number
    ] func [index [integer!]] [
        insert stack pick stack index
        return null
    ]

    swap-top-2: operation [
        {Swap the top two items on the stack}
        tab tab
    ] func [] [
        move/part stack 1 1
        return null
    ]

    discard-top: operation [
        {Discard the top item on the stack}
        lf lf
    ] func [] [
        take stack
        return null
    ]

    slide-n-values: operation [
        {Slide n items off the stack, keeping the top item}
        tab lf Number
    ] func [n [integer!]] [
        take/part next stack n
        return null
    ]
]


do-arithmetic: func [operator [word!]] [
    ; note the first item pushed is the left of the operation.
    ; could do infix except Rebol's modulo is prefix (mod a b)

    insert stack do reduce [
        operator second stack first stack
    ]
    take/part next stack 2
    return null
]


Arithmetic: category [
    IMP: [tab space]

    description: {
        Arithmetic commands operate on the top two items on the stack, and
        replace them with the result of the operation. The first item pushed
        is considered to be left of the operator.

        The copy and slide instructions are an extension implemented in
        Whitespace 0.3 and are designed to facilitate the implementation of
        recursive functions. The idea is that local variables are referred to
        using [space tab space], then on return, you can push the return
        value onto the top of the stack and use [space tab lf] to discard the
        local variables.
    }

    add: operation [
        {Addition}
        space space
    ] func [] [
        do-arithmetic 'add
    ]

    subtract: operation [
        {Subtraction}
        space tab
    ] func [] [
        do-arithmetic 'subtract
    ]

    multiply: operation [
        {Multiplication}
        space lf
    ] func [] [
        do-arithmetic 'multiply
    ]

    divide: operation [
        {Integer Division}
        tab space
    ] func [] [
        do-arithmetic 'divide
    ]

    modulo: operation [
        {Modulo}
        tab tab
    ] func [] [
        do-arithmetic 'modulo
    ]
]


Heap-Access: category [
    IMP: [tab tab]

    description: {
        Heap access commands look at the stack to find the address of items
        to be stored or retrieved. To store an item, push the address then the
        value and run the store command. To retrieve an item, push the address
        and run the retrieve command, which will place the value stored in
        the location at the top of the stack.
    }

    store: operation [
        {Store}
        space
    ] func [] [
        ; hmmm... are value and address left on the stack?
        ; the spec does not explicitly say they are removed
        ; but the spec is pretty liberal about not mentioning it

        value: take stack
        address: take stack
        pos: select heap address
        either pos [
            poke pos 1 value
        ][
            repend heap [value address]
        ]

        take/part stack 2
        return null
    ]

    retrieve: operation [
        {Retrieve}
        tab
    ] func [] [
        ; again, the spec doesn't explicitly say to remove from stack
        address: take stack
        value: select heap address
        print ["retrieving" value "to stack from address:" address]
        insert stack value
        return null
    ]
]


Flow-Control: category [
    IMP: [lf]

    description: {
        Flow control operations are also common. Subroutines are marked by
        labels, as well as the targets of conditional and unconditional jumps,
        by which loops can be implemented. Programs must be ended by means of
        [lf lf lf] so that the interpreter can exit cleanly.
    }

    mark-location: operation [
        {Mark a location in the program}
        space space Label
    ] func [label [integer!] <local> address] [
        ;
        ; now we capture the end of this instruction...
        ;
        address: offset? program-start instruction-end

        pos: select labels label
        either pos [
            poke pos 1 address
        ][
            repend labels [label address]
        ]
        return null
    ]

    call-subroutine: operation [
        {Call a subroutine}
        space tab Label
    ] func [label [integer!] <local> current-offset] [
        ;
        ; Call subroutine must be able to find the current parse location
        ; (a.k.a. program counter) so it can put it in the callstack.
        ;
        current-offset: offset? instruction-start program-start
        insert callstack current-offset
        return lookup-label-offset label
    ]

    jump-to-label: operation [
        {Jump unconditionally to a Label}
        space lf Label
    ] func [label [integer!]] [
        return lookup-label-offset label
    ]

    jump-if-zero: operation [
        {Jump to a Label if the top of the stack is zero}
        tab space Label
    ] func [label [integer!]] [
        ; must pop stack to make example work
        if zero? take stack [
            return lookup-label-offset label
        ]
        return null
    ]

    jump-if-negative: operation [
        {Jump to a Label if the top of the stack is negative}
        tab tab Label
    ] func [label [integer!]] [
        ; must pop stack to make example work
        if 0 > take stack [
            return lookup-label-offset label
        ]
        return null
    ]

    return-from-subroutine: operation [
        {End a subroutine and transfer control back to the caller}
        tab lf
    ] func [] [
        if empty? callers [
            print "RUNTIME ERROR: return with no callstack!"
            quit
        ]
        return take callstack
    ]

    end-program: operation [
        {End the program}
        lf lf
    ] func [] [
        ;
        ; Requesting to jump to the address at the end of the program will be
        ; the same as reaching it normally, terminating the PARSE interpreter.
        ;
        return length of program-start
    ]
]


IO: category [
    IMP: [tab lf]

    description: {
        Finally, we need to be able to interact with the user. There are IO
        instructions for reading and writing numbers and individual characters.
        With these, string manipulation routines can be written (see examples
        to see how this may be done).

        The read instructions take the heap address in which to store the
        result from the top of the stack.

        Note: spec didn't say we should pop the stack when we output, but
        the sample proves we must!
    }

    output-character-on-stack: operation [
        {Output the character at the top of the stack}
        space space
    ] func [] [
        print [as issue! first stack]
        take stack
        return null
    ]

    output-number-on-stack: operation [
        {Output the number at the top of the stack}
        space tab
    ] func [] [
        print [first stack]
        take stack
        return null
    ]

    read-character-to-location: operation [
        {Read a character to the location given by the top of the stack}
        tab space
    ] func [] [
        print "READ-CHARACTER-TO-LOCATION NOT IMPLEMENTED"
        return null
    ]

    read-number-to-location: operation [
        {Read a number to the location given by the top of the stack}
        tab tab
    ] func [] [
        print "READ-NUMBER-TO-LOCATION NOT IMPLEMENTED"
    ]
]


;
; RUNTIME VIRTUAL MACHINE OPERATIONS
;

; start out with an empty stack
stack: []

; callstack is separate from data stack
callstack: []

; a map is probably not ideal
heap: make map! []

; from Label # to program character index
labels: make map! []

binary-string-to-int: func [s [text!] <local> pad] [
    ; debase makes bytes, so to use it we must pad to a
    ; multiple of 8 bits.  better way?
    pad: unspaced array/initial (8 - modulo (length of s) 8) #"0"
    return to-integer debase/base unspaced [pad s] 2
]

whitespace-number-to-int: func [w [text!] <local> bin] [
    ; first character indicates sign
    sign: either space == first w [1] [-1]

    ; rest is binary value
    bin: copy next w
    replace/all bin space "0"
    replace/all bin tab "1"
    replace/all bin lf ""
    return sign * (binary-string-to-int bin)
]

lookup-label-offset: func [label [integer!]] [
    address: select labels label
    if null? address [
        print ["RUNTIME ERROR: Jump to undefined Label #" label]
        quit
    ]
    return address
]



;
; REBOL PARSE-BASED INTERPRETER FOR WHITESPACE LANGUAGE
;

; if the number rule matches, then param will contain the
; integer value of the decoded result
Number: [
    copy encoded [some [space | tab] lf] (
        param: whitespace-number-to-int encoded
    )
]

; according to the spec, labels are simply [lf] terminated
; lists of spaces and tabs.  So treating them as Numbers is fine.
Label: Number

pass: 1

max-execution-steps: 1000
debug-steps: true
extended-debug-steps: false

whitespace-vm-rule: [
    ; capture start of program
    program-start:

    ; initialize count
    (execution-steps: 0)

    ; begin matching parse patterns
    any [ 1 [
        ; capture current parse position as start of instruction
        instruction-start:

        (
            if (execution-steps > max-execution-steps) [
                print ["MORE THAN" execution-steps "INSTRUCTIONS EXECUTED"]
                quit
            ]
        )

        Stack-Manipulation/IMP [
            Stack-Manipulation/push/command (
                instruction: compose [push (param)]
            )

            | Stack-Manipulation/duplicate-top/command (
                instruction: copy [duplicate-top]
            )

            | Stack-Manipulation/duplicate-indexed/command (
                instruction: compose [duplicate-indexed (param)]
            )

            | Stack-Manipulation/swap-top-2/command (
                instruction: copy [swap-top-2]
            )

            | Stack-Manipulation/discard-top/command (
                instruction: copy [discard-top]
            )

            | Stack-Manipulation/slide-n-values/command (
                instruction: compose [slide-n-values (param)]
            )
        ]

        | Arithmetic/IMP [
            Arithmetic/add/command (
                instruction: copy [add]
            )

            | Arithmetic/subtract/command (
                instruction: copy [subtract]
            )

            | Arithmetic/multiply/command (
                instruction: copy [multiply]
            )

            | Arithmetic/divide/command (
                instruction: copy [divide]
            )

            | Arithmetic/modulo/command (
                instruction: copy [mod]
            )
        ]

        | Heap-Access/IMP [
            Heap-Access/store/command (
                instruction: copy [store]
            )

            | Heap-Access/retrieve/command (
                instruction: copy [retrieve]
            )
        ]

        | Flow-Control/IMP [
            Flow-Control/mark-location/command (
                ; This special instruction is ignored, unless it's the
                ; first pass...
                instruction: compose [mark-location (param)]
            )

            | Flow-Control/call-subroutine/command (
                instruction: compose [call-subroutine (param)]
            )

            | Flow-Control/jump-to-label/command (
                instruction: compose [jump-to-label (param)]
            )

            | Flow-Control/jump-if-zero/command (
                instruction: compose [jump-if-zero (param)]
            )

            | Flow-Control/jump-if-negative/command (
                instruction: compose [jump-if-negative (param)]
            )

            | Flow-Control/return-from-subroutine/command (
                instruction: copy [return-from-subroutine]
            )

            | Flow-Control/end-program/command (
                instruction: copy [end-program]
            )
        ]

        | IO/IMP [
            IO/output-character-on-stack/command (
                instruction: copy [output-character-on-stack]
            )

            | IO/output-number-on-stack/command (
                instruction: copy [output-number-on-stack]
            )

            | IO/read-character-to-location/command (
                instruction: copy [read-character-to-location]
            )

            | IO/read-number-to-location/command (
                instruction: copy [write-character-to-location]
            )
        ]
    ]
        ; Capture the current parse position at end of instruction
        instruction-end:

        ; execute the VM code and optionally give us debug output
        (
            ; This debugging output is helpful if there are malfunctions
            if extended-debug-steps [
                print [
                    "S:" offset? program-start instruction-start
                    "E:" offset? program-start instruction-end
                    "->"
                    mold copy/part instruction-start instruction-end
                ]
            ]

            ; default to whatever is next, which is where we
            ; were before this code
            next-instruction: instruction-end

            ; !!! The original implementation put the functions to handle the
            ; opcodes in global scope, so when an instruction said something
            ; like [jump-if-zero] it would be found.  Now the functions are
            ; inside one of the category objects.  As a temporary measure to
            ; keep things working, just try binding the instruction in all
            ; the category objects.
            ;
            ; !!! Also, this isn't going to give you an ACTION!, it gives an
            ; OBJECT! which has an action as a member.  So you have to pick
            ; the action out of it.  Very ugly...fix this soon!

            word: take instruction

            word: any [
                in Stack-Manipulation word
                in Arithmetic word
                in Heap-Access word
                in Flow-Control word
                in IO word
            ] else [
                fail "instruction WORD! not foundin any of the categories"
            ]

            ; !!! Furthering the hackishness of the moment, we bind to an
            ; action in the object with a field name the same as the word.
            ; So `push/push`, or `add/add`.  See OPERATION for a description
            ; of why we're doing this for now.
            ;
            word: non null in get word word
            ensure action! get word
            insert instruction word

            either 'mark-location == word [
                if (pass == 1) [
                    if debug-steps [
                        print ["(" mold instruction ")"]
                    ]

                    ; the first pass does the Label markings...
                    ensure null do instruction
                ]
            ][
                if (pass == 2) [
                    if debug-steps [
                        print ["(" mold instruction ")"]
                    ]

                    ; most instructions run on the second pass...
                    result: do instruction

                    if not null? result [
                        ; if the instruction returned a value, use
                        ; as the offset of the next instruction to execute
                        next-instruction: skip program-start result
                    ]

                    execution-steps: execution-steps + 1
                ]
            ]
        )

        ; Set the parse position to whatever we set in the code above
        :next-instruction
    ]
]


;
; SAMPLE PROGRAM
;
; Here is an annotated example of a program which counts from 1
; to 10, outputting the current value as it goes.
;
; This program was given as an example in the whitespace docs:
;
;     http://compsoc.dur.ac.uk/whitespace/tutorial.php
;
; Note that space, tab, lf are defined in Rebol.  The UNSPACED
; operation turns this into a bona-fide string.  But it's "easier
; to read" (or at least, to add comments) when we start out as a
; block of symbols we reduce to characters.
;

program: unspaced [

    ; Put a 1 on the stack
    space space space tab lf

    ; Set a Label at this point
    lf space space space tab space space  space space tab tab lf

    ; Duplicate the top stack item
    space lf space

    ; Output the current value
    tab lf space tab

    ; Put 10 (newline) on the stack...
    space space space tab space tab space lf

    ; ...and output the newline
    tab lf space space

    ; Put a 1 on the stack
    space space space tab lf

    ; Addition. This increments our current value.
    tab space space space

    ; Duplicate that value so we can test it
    space lf space

    ; Push 11 onto the stack
    space space space tab space tab tab lf

    ; Subtraction. So if we've reached the end, we have a zero on the stack.
    tab space space tab

    ; If we have a zero, jump to the end
    lf tab space space tab space space  space tab space tab lf

    ; Jump to the start
    lf space lf space tab space  space space space tab tab lf

    ; Set the end Label
    lf space space space tab space  space space tab space tab lf

    ; Discard our accumulator, to be tidy
    space lf lf

    ; Finish!
    lf lf lf
]


;
; QUICK CHECK FOR VALID INPUT
;

separator: "---"

print "WHITESPACE INTERPRETER FOR PROGRAM:"
print separator
print mold program
print separator

;
; LABEL SCANNING PASS
;
; We have to scan the program for labels before we run it
; Also this tells us if all the constructions are valid
; before we start running
;

print "LABEL SCAN PHASE"

pass: 1
unless parse program whitespace-vm-rule [
    print "INVALID INPUT"
    quit
]

print mold labels
print separator

;
; PROGRAM EXECUTION PASS
;
; The Rebol parse dialect has the flexibility to do arbitrary
; seeks to locations in the input.  This makes it possible to
; apply it to a language like whitespace
;

pass: 2
either parse program whitespace-vm-rule [
    print "Program End Encountered"
    print ["stack:" mold stack]
    print ["callstack:" mold callstack]
    print ["heap:" mold heap]
][
    print "UNEXPECTED TERMINATION (Internal Error)"
]
