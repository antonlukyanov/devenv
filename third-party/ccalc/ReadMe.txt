CCALC provides convenient way to for performing calculations. You can
use standard infix notation for expressions and store results in variables. 

Input for this calculator are normal C expressions containing operators, float
or integer constants, variables and and references to previous results ($n).
Precedence and semantic of operators is the same as in C language. There are
two extra binary operators: >>> unsigned shift right and ** raising to power.
Type of variable (integer or float) depends on assigned value. All conversions
are done implicitly but there are two functions int() and float() to perform
explicit conversion. Initially all variables are assigned 0 value.
Calculator supports standard set of functions from C mathematics library and
also defines function prime(n), which returns smallest prime number >= n.
For integer expressions decimal, hexadecimal and octal outputs are produced.

Operators:
	++ -- ! ~ unary + -
	**
	* / %
	+ -
	<< >> >>>
	< <= > >= 
	== != 
	&
	^
	|
	= += -= *= /= %= <<= >>= >>>= &= |= ^= **= 

Functions:
	abs	atan	cosh	float	prime	sqrt
	acos	atan2	exp	log	sin	tan
	asin 	cos	int	log10	sinh	tanh

Type "exit" or "quit" to terminate program, "help" or "?" to show this text.

CCALC is freeware and is distributed in hope to be useful. Please submit bug 
reports to the following e-mail address: knizhnik@altavista.net

Please visit my homepage for other freeware programming staff:
		http://www.ispras.ru/~knizhnik



