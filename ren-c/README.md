This is an interpreter for the Whitespace language, using the Ren-C branch
of Rebol3:

    http://compsoc.dur.ac.uk/whitespace/

    https://github.com/metaeducation/ren-c

Although Whitespace was invented as a joke, making a working implementation
has much of the spirit of a "real" programming task.  The existence of
implementations in Haskell, Ruby, Perl, C++, and Python mean it is possible to
take a real look at the contrast in how you can approach the problem.

Any sensible implementation of a task like this will be somewhat table-driven
(or more generally, "specification-driven").  Otherwise you end up with
unmaintainable spaghetti code.  For example, the Perl implementation has this:

    my %cmd_list = qw ( AAn push_number
        ACA duplicate_last
        ACB swap_last
        ACC pop_number
        BAAA add
        BAAB subtract
        BAAC multiply
        BABA div
        BABB mod
        BBA store
        BBB retrieve
        CAAl set_Label
        CABl call_Label
        CACl jump
        CBAl jump_ifzero
        CBBl jump_negative
        CBC ret
        CCC end
        BCAA print_char
        BCAB print_num
        BCBA read_char
        BCBB read_num );

What is demonstrated by the Ren-C version is that you can bend the language to
make your program work more closely in the terminology of the specification.

Authors of code like the Perl version could have been more verbose.  But
because the languages aren't homoiconic, it's harder to get value from them.
You end up putting your internal specs into strings and parsing them.  Why not
skip the middleman and use structural expression, which can be reflected out as
debugging information...for free?!

As an added gimmick for this implementation, it uses Rebol's PARSE dialect
for more than just analyzing the whitespace sequences.  It's also the virtual
machine!!!

It uses the fact that when you give the parser input to process, you can
programmatically move the parser position--back to something you've already
parsed, or forward to something you haven't seen yet.  Consequently it can be
used as a program counter!  This happens to work for the whitespace VM, though
it's probably not the best solution.  It's kind of a pun, and only done to show
an axis of flexibility in PARSE.
