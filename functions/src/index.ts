import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
type Firestore = admin.firestore.Firestore;
const app = admin.initializeApp();

export const onDeleteCollection = functions.firestore.document('collections/{collectionID}')
  .onDelete((snap, context) => {
      const {collectionID} = context.params
      const db = app.firestore();
      return deleteAllItemsInCollection(db, collectionID, 10)
    }
  )

async function deleteAllItemsInCollection(db: Firestore, collectionID: string, batchSize: 10) {
  const collectionRef = db.collection(`collectionItems/${collectionID}/items`);
  const query = collectionRef.orderBy('__name__').limit(batchSize);

  return new Promise((resolve, reject) => {
    deleteQueryBatch(db, query, resolve, reject);
  });
}

function deleteQueryBatch(db: Firestore, query: any, resolve: any, reject: any) {
  query.get()
    .then((snapshot: any) => {
      // When there are no documents left, we are done
      if (snapshot.size === 0) {
        return 0;
      }

      // Delete documents in a batch
      const batch = db.batch();
      snapshot.docs.forEach((doc: any) => {
        batch.delete(doc.ref);
      });

      return batch.commit().then(() => {
        return snapshot.size;
      });
    }).then((numDeleted: number) => {
      if (numDeleted === 0) {
        resolve();
        return;
      }

      // Recurse on the next process tick, to avoid
      // exploding the stack.
      process.nextTick(() => {
        deleteQueryBatch(db, query, resolve, reject);
      });
    })
    .catch(reject);
}

export const onDeleteItem = functions.firestore.document('collectionItems/{collectionID}/items/{itemID}')
  .onDelete(
    (snap, context) => {
      const { collectionID } = context.params;
      const { itemID } = context.params
      return deleteItemImage(collectionID, itemID)
    }
  )

async function deleteItemImage(collectionID: string, itemID: string) {
  const path = `images/${collectionID}/${itemID}`;
  const bucket = app.storage().bucket();
  return bucket.file(path).delete()
    .then(function () {
      console.log(`File deleted successfully in path: ${path}`)
    }).catch(function (error) {
      console.log(`File NOT deleted: ${path}   Error: ${error}`)
    });
}

// async function deleteAllCollectionImages(collectionID: string){
//     const bucket = app.storage().bucket();
//     return bucket.deleteFiles({
//       prefix: `images/${collectionID}`
//     });
//   };

