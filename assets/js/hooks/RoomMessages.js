import { init, Picker } from 'emoji-mart'
import data from '@emoji-mart/data'

init({ data })

const RoomMessages = {
  mounted() {
    this.el.scrollTop = this.el.scrollHeight;
    this.handleEvent("scroll_messages_to_bottom", () => {
      this.el.scrollTop = this.el.scrollHeight;
    });

    this.canLoadMore = true;

    this.el.addEventListener("scroll", _e => {
      if (this.canLoadMore && this.el.scrollTop < 100) {
        this.canLoadMore = false;
        const prevHeight = this.el.scrollHeight;

        this.pushEvent("load-more-messages", {}, (reply) => {
          this.el.scrollTo(0, this.el.scrollHeight - prevHeight);

          this.canLoadMore = reply.can_load_more;
        });
      }
    })

    this.handleEvent("reset_pagination", ({can_load_more}) => {
      this.canLoadMore = can_load_more;
    });

    this.handleEvent("update_avatar", ({user_id, avatar_path}) => {
      const avatars = this.el.querySelectorAll(`img[data-user-avatar-id="${user_id}"]`);

      avatars.forEach(function(avatar) {
        avatar.src = `/uploads/${avatar_path}`;
      });
    });

    this.el.addEventListener("show_emoji_picker", e => {
      const picker = new Picker({
        onEmojiSelect: (selection) => {
          this.pushEvent("add-reaction", {
            emoji: selection.native,
            message_id: e.detail.message_id,
          });

          this.closePicker()
        },
        onClickOutside: () => this.closePicker(),
      });
      picker.id = "emoji-picker";
      const wrapper = document.getElementById("emoji-picker-wrapper");
      wrapper.appendChild(picker)
      
      const message = document.getElementById(`messages-${e.detail.message_id}`)
      const rect = message.getBoundingClientRect();

      if (rect.top + wrapper.clientHeight > window.innerHeight) {
        wrapper.style.bottom = `20px`;
      } else {
        wrapper.style.top = `${rect.top}px`;
      }
      wrapper.style.right = '50px';
    });
  },

  closePicker() {
    const picker = document.getElementById('emoji-picker');
    if (picker) {
      picker.parentNode.removeChild(picker);
    }
  }
};

export default RoomMessages;
