const RoomMessages = {
  mounted() {
    this.handleEvent("scroll_messages_to_bottom", () => {
      const messagePane = document.getElementById('room-messages');
      messagePane.scrollTop = messagePane.scrollHeight;
    });
  }
};

export default RoomMessages;
