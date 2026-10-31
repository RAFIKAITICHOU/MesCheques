import '../database/persons_dao.dart';
import '../models/person.dart';

class PersonRepository {
  final PersonsDao _dao;

  PersonRepository({PersonsDao? dao}) : _dao = dao ?? PersonsDao();

  Future<Person> findOrCreate(String name) => _dao.findOrCreate(name);

  Future<List<Person>> search(String query, {int limit = 8}) =>
      _dao.search(query, limit: limit);

  Future<List<Person>> getAll() => _dao.getAll();

  Future<Person?> getById(int id) => _dao.getById(id);
}
