#pragma warning (disable:4786)


#include <iostream>
#include <fstream>
#include <vector>
#include <map>

#include <assert.h>
#include <typeinfo.h>

using namespace std;

class Op
{
public:
	Op()
	{
	}
	
	virtual ~Op()
	{
	}

	virtual void run( class Vm& vm )
	{
	}

	virtual char* getName( ) = 0;

	virtual void getRunInfo( ostream& out )
	{
		out << getName();
	}

	virtual bool isLabel() { return false; };
	
	// helper
	void putInHeap( class Vm& vm, int i, int v );
};

class OpClass
{
public:
	OpClass()
	{
	}
	
	virtual ~OpClass()
	{
	}


	virtual char* getSignature() = 0;

	virtual bool read( string s, Op*& op, int& length ) = 0;
};


class Vm
{
public:
	bool running;
	bool debug;
	int ip;
	vector<int> stack;
	vector<int> heap;
	vector< Op* > ops;
	map< int, int > labels;
	vector< OpClass* > allOpClasses;


	Vm();

	~Vm()
	{
		for( int i3 = 0; i3 < allOpClasses.size(); ++ i3 )
		{
			delete allOpClasses[i3];
		}
		allOpClasses.clear();

		for( int i2 = 0; i2 < ops.size(); ++ i2 )
		{
			delete ops[i2];
		}
		ops.clear();
	}

	void run()
	{
		running = true;
		ip = 0;

		while( running )
		{
			if( ip >= ops.size() )
			{
				running = false;
			}
			else
			{
				assert( ip >= 0 );
				assert( ip < ops.size() );
				Op* op = ops[ip];
				assert( op );
				++ ip;
				if( debug )
				{
					cout << ip << " ";
					op->getRunInfo( cout );
					cout << endl;
				}

				op->run( *this );
			}
		}
	}

	void buildLabels();

	void buildOps( const string& data_byte_code )
	{
		string data_byte_code_2( data_byte_code );
		while( data_byte_code_2.length() )
		{
			Op* op = NULL;
			int length = 0;
			for( int i = 0; (i < allOpClasses.size()) && (!op); ++ i )
			{
				OpClass& oc = *allOpClasses[i];
				if( oc.read( data_byte_code_2, op, length ) )
				{
					assert( op );
					assert( length >= 0 );
				}
				else
				{
					op = NULL;
					length = 0;
				}
			}

			if( op == NULL )
			{
				cout << "can not parse: " << data_byte_code_2.substr( 0, 50 ).c_str() << endl;
				length = 1;
				op = NULL;
			}

			if( length >= 0 )
			{
				data_byte_code_2.erase( 0, length );
			}

			if( op )
			{
				ops.push_back( op );
			}
		}
	}
};

void Op::putInHeap( Vm& vm, int i, int v )
{
	assert( i >= 0 );
	vm.heap.resize( __max( vm.heap.size(), i + 1 ) );
	vm.heap[i] = v;
}

template< class Base >
class OpTemplateClass: public OpClass
{
	virtual char* getSignature()
	{
		return Base::getSignature();
	}

	virtual bool read( string s, Op*& op, int& length )
	{
		string sig = getSignature();
		string sig2 = s.substr( 0, sig.length() );
		if( sig.compare(sig2) == 0 )
		{
			length = sig.length();

			int subLen = 0;
			string subStr = s.substr( length, s.length() - length );
			op = new Base( subStr, subLen );
			if( subLen >= 0 )
			{
				length += subLen;
				return true;
			}
			else
			{
				delete op;
				return false;
			}
		}
		else
		{
			return false;
		}

	}
};

#include "ops.h"


void Vm::buildLabels()
{
	for( int i = 0; i < ops.size(); ++ i )
	{
		Op* op = ops[i];
		assert( op );
		if( op->isLabel() )
		{
			OpLabel* l = (OpLabel*) op;

			assert( labels.find(l->label) == labels.end() );
			
			labels[l->label] = i;
			//.add( make_pair( l->label, i );
		}

	}
}

Vm::Vm()
	:running( true ),
	ip( 0 ),
	debug( false )
{
	allOpClasses.push_back( new OpClassPush );
	allOpClasses.push_back( new OpClassPop );
	allOpClasses.push_back( new OpClassLabel );
	allOpClasses.push_back( new OpClassDoub );
	allOpClasses.push_back( new OpClassSwap );
	allOpClasses.push_back( new OpClassAdd );
	allOpClasses.push_back( new OpClassSub );
	allOpClasses.push_back( new OpClassMul );
	allOpClasses.push_back( new OpClassDiv );
	allOpClasses.push_back( new OpClassMod );
	allOpClasses.push_back( new OpClassStore );
	allOpClasses.push_back( new OpClassRetrive );
	allOpClasses.push_back( new OpClassCall );
	allOpClasses.push_back( new OpClassJump );
	allOpClasses.push_back( new OpClassJumpZ );
	allOpClasses.push_back( new OpClassJumpN );
	allOpClasses.push_back( new OpClassRet );
	allOpClasses.push_back( new OpClassExit );
	allOpClasses.push_back( new OpClassOutC );
	allOpClasses.push_back( new OpClassOutN );
	allOpClasses.push_back( new OpClassInC );
	allOpClasses.push_back( new OpClassInN );
	allOpClasses.push_back( new OpClassDebugPrintStack );
	allOpClasses.push_back( new OpClassDebugPrintHeap );
}




int main( int argc, char* argv[] )
{
	bool debug = false; 

    cout << "WhiteSpace interpreter in C++ (speedy!!)" << endl;
    cout << "Made by Oliver Burghard Smarty21@gmx.net" << endl;
    cout << "in his free time for your and his joy" << endl;
    cout << "good time and join me to get Whitespace ready for business" << endl;
    cout << "For any other information dial 1-900-WHITESPACE" << endl;
    cout << "Or get soon info at www.WHITESPACE-WANTS-TO-BE-TAKEN-SERIOUS.org" << endl;
    cout << "-- WS Interpreter C++ ------------------------------------------" << endl;

	if( argc < 2 )
	{
		cout << "wsinter [filename] [-d]" << endl;
	}
	else
	{
		ifstream filein( argv[1] );
		filein.seekg( 0, ios::end );
		int size = filein.tellg();
		assert( size >= 0 );
		filein.seekg( 0, ios::beg );

		if( ( argc > 2 ) && ( strcmp( argv[2], "-d" ) == 0 ) )
		{
			debug = true;
		}

		char* buffer = new char[size];
		filein.read( buffer, size );
		int nsize = filein.gcount();
//		assert( nsize == size );

		string file( buffer, nsize );
		
		
		delete [] buffer;

		string data_byte_code;
		data_byte_code.reserve( file.length() );
		for( int i = 0; i < file.length(); ++ i )
		{
			char ch = file[i];
			if( ch == ' ' )
			{
				data_byte_code += 'a';
			}
			else if( ch == '\t' )
			{
				data_byte_code += 'b';
			}
			else if( ch == '\n' )
			{
				data_byte_code += 'c';
			}
			else
			{
			}
		}



		Vm vm;

		if( debug )
		{
			vm.debug = true;
		}

		vm.buildOps( data_byte_code );
		vm.buildLabels();

		vm.run();

//		cout << "done" << endl;

//		int i6;
//		cin >> i6;
	}

	return 0;
}