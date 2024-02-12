const ChatMessageTextarea = {
  mounted() {
    this.el.addEventListener('keydown', e => {
      if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();

        document.getElementById("new-message-form").dispatchEvent(
          new Event("submit", {bubbles: true, cancelable: true})
        );
      }
    });
  }
};

export default ChatMessageTextarea;
