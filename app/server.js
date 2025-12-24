const express = require('express');
const { google } = require('googleapis');
const cors = require('cors');
const path = require('path');

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.static(__dirname));

// ========== CONFIGURE THIS ==========
const CALENDAR_ID = 'redacted@group.calendar.google.com';
// ====================================

// Load Service Account credentials
const auth = new google.auth.GoogleAuth({
  keyFile: './credentials.json',
  scopes: ['https://www.googleapis.com/auth/calendar'],
});

const calendar = google.calendar({ version: 'v3', auth });

// Get events for a date range
app.get('/api/events', async (req, res) => {
  try {
    const { timeMin, timeMax } = req.query;
    
    const response = await calendar.events.list({
      calendarId: CALENDAR_ID,
      timeMin: timeMin,
      timeMax: timeMax,
      singleEvents: true,
      orderBy: 'startTime',
      maxResults: 100,
    });

    res.json(response.data.items || []);
  } catch (error) {
    console.error('Error fetching events:', error.message);
    res.status(500).json({ error: error.message });
  }
});

// Add a new event
app.post('/api/events', async (req, res) => {
  try {
    const { summary, startDateTime, endDateTime, colorId } = req.body;
    
    const response = await calendar.events.insert({
      calendarId: CALENDAR_ID,
      resource: {
        summary: summary,
        start: { 
          dateTime: startDateTime,
          timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone 
        },
        end: { 
          dateTime: endDateTime,
          timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone 
        },
        colorId: colorId,
      },
    });

    res.json(response.data);
  } catch (error) {
    console.error('Error adding event:', error.message);
    res.status(500).json({ error: error.message });
  }
});

// Delete an event
app.delete('/api/events/:eventId', async (req, res) => {
  try {
    await calendar.events.delete({
      calendarId: CALENDAR_ID,
      eventId: req.params.eventId,
    });

    res.json({ success: true });
  } catch (error) {
    console.error('Error deleting event:', error.message);
    res.status(500).json({ error: error.message });
  }
});

// Health check
app.get('/api/health', async (req, res) => {
  try {
    await calendar.calendarList.list({ maxResults: 1 });
    res.json({ status: 'connected', calendarId: CALENDAR_ID });
  } catch (error) {
    res.status(500).json({ status: 'error', message: error.message });
  }
});

// Serve the calendar HTML
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'calendar.html'));
});

// Save WiFi credentials
app.post('/api/wifi', async (req, res) => {
  const { ssid, password } = req.body;
  const fs = require('fs').promises;
  const { exec } = require('child_process');

  // exec(`sudo nmcli dev wifi`, (error, stdout, stderr) => {
  //   if (error) {
  //     res.status(500).json({ error: stderr || error.message });
  //   }
  // });

  try {
    // Save to file
    await fs.writeFile('/home/kiosk/wifi-credentials.txt', 
      `SSID: ${ssid}\nPassword: ${password}\n`);
    
    // Also create wpa_supplicant format for easy copying
    const wpaConfig = `network={\n  ssid="${ssid}"\n  psk="${password}"\n  key_mgmt=WPA-PSK\n}`;
    await fs.writeFile('/home/kiosk/wifi-config.txt', wpaConfig);
    
    res.json({ success: true, message: 'WiFi credentials saved' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Apply WiFi (optional - requires sudo permissions)
app.post('/api/wifi/connect', async (req, res) => {
  const { exec } = require('child_process');
  const { ssid, password } = req.body;

  // exec(`sudo nmcli dev wifi connect "${ssid}" password "${password}"`, (error, stdout, stderr) => {
  exec(`sudo ./set_wifi.sh "${ssid}" "${password}" wlan0`, (error, stdout, stderr) => {
    if (error) {
      res.status(500).json({ error: stderr || error.message });
    } else {
      res.json({ success: true, message: 'Connected to WiFi' });
    }
  });
});


const PORT = 3000;
app.listen(PORT, () => {
  console.log('');
  console.log('🗓️  Family Calendar Kiosk');
  console.log('========================');
  console.log(`✅ Server running at: http://localhost:${PORT}`);
  console.log(`📅 Calendar ID: ${CALENDAR_ID}`);
  console.log('');
  console.log('Open http://localhost:3000 in your browser');
  console.log('Press Ctrl+C to stop');
  console.log('');
});
