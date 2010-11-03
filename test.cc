#include <iostream>

#include <boost/lexical_cast.hpp>

#include "julea.h"

using namespace boost;
using namespace std;
using namespace JULEA;

int main (int argc, char** argv)
{
	if (argc < 2)
	{
		return 1;
	}

	Store s(argv[1]);
	Semantics semantics;
	list<Collection> collections;

	semantics
		->SetConsistency(Consistency::Strict)
		->SetPersistency(Persistency::Strict)
		->SetConcurrency(Concurrency::Strict)
		->SetSecurity(Security::Strict);

//	s->SetSemantics(semantics);

	for (int j = 0; j < 10; j++)
	{
		string name("test-" + lexical_cast<string>(j));

		collections.push_back(Collection(name));
	}

	s->Create(collections);

	list<Collection>::iterator it;

	for (it = collections.begin(); it != collections.end(); ++it)
	{
		list<Item> items;

		for (int i = 0; i < 10000; i++)
		{
			string name("test-" + lexical_cast<string>(i));
			Item item(name);

	//		item->SetSemantics(semantics);
			items.push_back(item);
		}

		(*it)->Create(items);
	}

	/*
	Collection::Iterator i(Collection("test-3"));

	while (i.More())
	{
		Item f = i.Next();

		cout << f.Name() << endl;
	}
	*/

	return 0;
}
