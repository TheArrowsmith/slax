const RoomMessages = {
  mounted() {
    this.el.scrollTop = this.el.scrollHeight;
    this.handleEvent("scroll_messages_to_bottom", () => {
      this.el.scrollTop = this.el.scrollHeight;
    });

    this.handleEvent("update_avatar", ({user_id, avatar_path}) => {
      const avatars = this.el.querySelectorAll(`img[data-user-avatar-id="${user_id}"]`);

      avatars.forEach(function(avatar) {
        avatar.src = `/uploads/${avatar_path}`;
      });
    });
  }
};

export default RoomMessages;
