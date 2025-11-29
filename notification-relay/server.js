import express from 'express';
import fetch from 'node-fetch';
import cors from 'cors';
import dotenv from 'dotenv';
dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

// Protect this endpoint. Use real auth in production.
const ADMIN_SECRET = process.env.ADMIN_SECRET; // set in .env
const ONESIGNAL_APP_ID = process.env.ONESIGNAL_APP_ID;
const ONESIGNAL_REST_KEY = process.env.ONESIGNAL_REST_KEY;

app.post('/send-notification', async (req, res) => {
  try {
    const auth = req.headers['x-admin-secret'];
    if (!ADMIN_SECRET || auth !== ADMIN_SECRET) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    // body example:
    // { "head": "Emergency!", "body": "Fire at Building B", "filters": [{ "field":"tag", "key":"user_id", "relation":"=", "value":"UID" }] }
    const { head, body, filters, include_player_ids } = req.body;

    const payload = {
      app_id: ONESIGNAL_APP_ID,
      headings: { en: head || 'Alert' },
      contents: { en: body || '' },
      // either use filters (tag-based) OR include_player_ids OR send to all
      ...(filters ? { filters } : {}),
      ...(include_player_ids ? { include_player_ids } : {}),
      android_group: 'admin_broadcast', // optional grouping
      ios_badgeType: 'Increase',
      ios_badgeCount: 1
    };

    const r = await fetch('https://onesignal.com/api/v1/notifications', {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${ONESIGNAL_REST_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(payload)
    });

    const data = await r.json();
    if (!r.ok) {
      return res.status(500).json({ error: data });
    }
    return res.json(data);
  } catch (e) {
    console.error(e);
    return res.status(500).json({ error: e.toString() });
  }
});

const port = process.env.PORT || 3000;
app.listen(port, () => console.log(`Notification relay running on ${port}`));
