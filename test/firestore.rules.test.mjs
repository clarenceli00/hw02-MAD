import { readFileSync } from 'node:fs';
import { before, after, beforeEach, test } from 'node:test';
import assert from 'node:assert/strict';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, setDoc, getDoc, updateDoc, deleteDoc, serverTimestamp, Timestamp } from 'firebase/firestore';

// Isolated emulator namespace: clearing tests cannot erase app demo records.
const projectId = 'demo-hw02-rules-tests';
let env;
const message = (uid = 'alice') => ({ authorUid: uid, authorName: 'Test Author', text: 'Test message', createdAt: serverTimestamp() });
const db = (uid) => env.authenticatedContext(uid).firestore();

before(async () => {
  env = await initializeTestEnvironment({ projectId, firestore: {
    host: '127.0.0.1', port: 8080,
    rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'),
  }});
});
beforeEach(async () => { await env.clearFirestore(); });
after(async () => { await env?.cleanup(); });

test('signed-out message read is denied', async () => {
  await assertSucceeds(setDoc(doc(db('alice'), 'messages/one'), message()));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'messages/one')));
});
test('cross-user update and delete are denied', async () => {
  await setDoc(doc(db('alice'), 'messages/one'), message());
  const target = doc(db('bob'), 'messages/one');
  await assertFails(updateDoc(target, { text: 'Stolen', editedAt: serverTimestamp() }));
  await assertFails(deleteDoc(target));
});
test('forged authorUid create is denied', async () => {
  await assertFails(setDoc(doc(db('bob'), 'messages/forged'), message('alice')));
});
test('correct author can create, read, update and delete', async () => {
  const target = doc(db('alice'), 'messages/one');
  await assertSucceeds(setDoc(target, message()));
  assert.equal((await assertSucceeds(getDoc(target))).data().text, 'Test message');
  await assertSucceeds(updateDoc(target, { text: 'Edited', editedAt: serverTimestamp() }));
  assert.equal((await getDoc(target)).data().text, 'Edited');
  await assertSucceeds(deleteDoc(target));
  assert.equal((await getDoc(target)).exists(), false);
});
test('owner cannot change ownership or original creation time', async () => {
  const target = doc(db('alice'), 'messages/one');
  await setDoc(target, message());
  await assertFails(updateDoc(target, { authorUid: 'bob', editedAt: serverTimestamp() }));
  await assertFails(updateDoc(target, { createdAt: Timestamp.fromMillis(0), editedAt: serverTimestamp() }));
});
test('profiles are private and registration date is preserved', async () => {
  const target = doc(db('alice'), 'users/alice');
  await assertSucceeds(setDoc(target, { uid: 'alice', firstName: 'Test', lastName: 'User', role: 'Student', registrationDateTime: serverTimestamp() }));
  await assertSucceeds(getDoc(target));
  const registrationDate = (await getDoc(target)).data().registrationDateTime;
  await assertFails(getDoc(doc(db('bob'), 'users/alice')));
  await assertFails(setDoc(doc(db('bob'), 'users/alice'), { uid: 'bob' }));
  await assertSucceeds(updateDoc(target, { firstName: 'Updated' }));
  assert.ok((await getDoc(target)).data().registrationDateTime.isEqual(registrationDate));
  await assertFails(updateDoc(target, { registrationDateTime: Timestamp.fromMillis(0) }));
});
