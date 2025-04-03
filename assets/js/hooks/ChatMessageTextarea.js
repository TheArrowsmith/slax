const ChatMessageTextarea = {
  mounted() {
    this.el.addEventListener('keydown', e => {
      if (e.key === 'Enter' && !e.shiftKey) {
        const form = document.getElementById("new-message-form");

        this.el.dispatchEvent(new Event("change", {bubbles: true, cancelable: true}));
        form.dispatchEvent(new Event("submit", {bubbles: true, cancelable: true}));
      }
    });
  }
};

export default ChatMessageTextarea;
