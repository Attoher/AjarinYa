const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { setGlobalOptions } = require('firebase-functions/v2');

initializeApp();
setGlobalOptions({ region: 'asia-southeast2', maxInstances: 10 });

const db = getFirestore();
const messaging = getMessaging();

/**
 * Mengambil FCM token milik seorang pengguna dari koleksi `users`.
 * Mengembalikan null jika pengguna tidak ditemukan atau belum pernah
 * login di perangkat manapun (belum memiliki token).
 */
async function getUserToken(userId) {
  if (!userId) return null;
  const snap = await db.collection('users').doc(userId).get();
  if (!snap.exists) return null;
  return snap.data().fcmToken || null;
}

/**
 * Mengirim satu push notification ke satu token perangkat lewat FCM.
 * Semua nilai pada `data` dikonversi ke string karena FCM data payload
 * hanya menerima Map<String, String>.
 */
async function sendNotification(token, title, body, data) {
  if (!token) return;
  try {
    await messaging.send({
      token,
      notification: { title, body },
      data: Object.fromEntries(
        Object.entries(data || {}).map(([key, value]) => [key, String(value)])
      ),
      android: { priority: 'high' },
    });
  } catch (error) {
    console.error('Gagal mengirim notifikasi ke token', token, error);
  }
}

/**
 * Trigger: pesan chat baru dibuat di
 * barter_requests/{requestId}/messages/{messageId}.
 * Mengirim push notification ke partner chat (peserta lain selain pengirim).
 */
exports.sendChatMessageNotification = onDocumentCreated(
  'barter_requests/{requestId}/messages/{messageId}',
  async (event) => {
    const message = event.data?.data();
    if (!message) return;

    const requestId = event.params.requestId;
    const requestSnap = await db.collection('barter_requests').doc(requestId).get();
    if (!requestSnap.exists) return;

    const request = requestSnap.data();
    const participantIds = [request.userId, request.matchedWith].filter(Boolean);
    const recipientId = participantIds.find((id) => id !== message.senderId);
    if (!recipientId) return;

    const token = await getUserToken(recipientId);
    if (!token) return;

    const body =
      message.text && message.text.trim().length > 0 ? message.text : 'Mengirim gambar';

    await sendNotification(token, message.senderName || 'Pesan Baru', body, {
      type: 'chat',
      requestId,
    });
  }
);

/**
 * Trigger: tawaran trade skill baru dibuat di barter_requests/{requestId}.
 * Mengirim push notification ke seluruh anggota grup yang sama, kecuali
 * pembuat tawaran itu sendiri.
 */
exports.sendBarterOfferNotification = onDocumentCreated(
  'barter_requests/{requestId}',
  async (event) => {
    const request = event.data?.data();
    if (!request || !request.groupId) return;

    const groupSnap = await db.collection('groups').doc(request.groupId).get();
    if (!groupSnap.exists) return;

    const memberIds = (groupSnap.data().memberIds || []).filter(
      (id) => id !== request.userId
    );
    if (memberIds.length === 0) return;

    const title = 'Tawaran Skill Baru';
    const body = `${request.userName || 'Seseorang'} ingin belajar "${request.wantToLearn}" dan bisa mengajar "${request.canTeach}"`;

    await Promise.all(
      memberIds.map(async (memberId) => {
        const token = await getUserToken(memberId);
        if (!token) return;
        await sendNotification(token, title, body, {
          type: 'barter_offer',
          requestId: event.params.requestId,
        });
      })
    );
  }
);

/**
 * Trigger: status tawaran trade skill berubah dari PENDING menjadi MATCHED.
 * Mengirim push notification ke pembuat tawaran bahwa tawarannya sudah
 * diterima oleh orang lain.
 */
exports.sendBarterMatchedNotification = onDocumentUpdated(
  'barter_requests/{requestId}',
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    if (!before || !after) return;

    if (before.status === 'PENDING' && after.status === 'MATCHED') {
      const token = await getUserToken(after.userId);
      if (!token) return;

      const title = 'Tawaran Diterima';
      const body = `${after.matchedWithName || 'Seseorang'} menerima tawaran trade skill kamu. Yuk mulai chat!`;

      await sendNotification(token, title, body, {
        type: 'barter_matched',
        requestId: event.params.requestId,
      });
    }
  }
);
