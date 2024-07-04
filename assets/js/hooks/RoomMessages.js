const RoomMessages = {
  mounted() {
    this.el.scrollTop = this.el.scrollHeight;
    this.handleEvent("scroll_messages_to_bottom", () => {
      this.el.scrollTop = this.el.scrollHeight;
    });
  }
};

export default RoomMessages;
