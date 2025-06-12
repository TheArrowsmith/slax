const Thread = {
  mounted() {
    const messageAndReplies = this.el.querySelector("#thread-message-with-replies")
    messageAndReplies.scrollTop = messageAndReplies.scrollHeight;

    this.handleEvent("scroll_thread_to_bottom", () => {
      messageAndReplies.scrollTop = messageAndReplies.scrollHeight;
    });

    this.handleEvent("update_avatar", ({user_id, avatar_path}) => {
      const avatars = this.el.querySelectorAll(`img[data-user-avatar-id="${user_id}"]`);

      avatars.forEach(function(avatar) {
        avatar.src = `/uploads/${avatar_path}`;
      });
    });
  }
};

export default Thread;
