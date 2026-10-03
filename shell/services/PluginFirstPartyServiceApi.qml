import QtQuick

// Narrow proxy for the non-authentication first-party services used by the
// built-in bar. It intentionally has no generic property or method forwarding.
QtObject {
  required property string ownerPluginId
  required property string serviceId

  property bool stayAwake: false
  property bool enabled: false
  property bool doNotDisturb: false
  property var activePlayer: null
  property var sourcePlayers: []

  property var _setIdleEnabled: null
  property var _setNightlight: null
  property var _setDoNotDisturb: null
  property var _runAction: null
  property var _playerKey: null
  property var _selectPlayer: null

  function setIdleEnabled(value) {
    if (serviceId === "agent0s.idle" && _setIdleEnabled) _setIdleEnabled(!!value)
  }

  function setNightlight(value) {
    if (serviceId === "agent0s.nightlight" && _setNightlight) _setNightlight(!!value)
  }

  function setDoNotDisturb(value) {
    if (serviceId === "agent0s.notifications" && _setDoNotDisturb) _setDoNotDisturb(!!value)
  }

  function runAction(action, showFeedback, playerId) {
    if (serviceId === "agent0s.media" && _runAction)
      _runAction(String(action || ""), !!showFeedback, String(playerId || ""))
  }

  function playerKey(player) {
    return serviceId === "agent0s.media" && _playerKey ? _playerKey(player) : ""
  }

  function selectPlayer(playerId) {
    if (serviceId === "agent0s.media" && _selectPlayer) _selectPlayer(String(playerId || ""))
  }
}
