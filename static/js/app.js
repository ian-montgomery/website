// Client-side interactions: square skill-chip popovers.
// Everything else (theme, icons) was removed for the 1-bit redesign.

document.addEventListener('DOMContentLoaded', () => {
  let activePopover = null;

  function hideActivePopover() {
    if (activePopover) {
      activePopover.style.display = 'none';
      activePopover = null;
    }
  }

  function showPopover(trigger, popover) {
    const isAlreadyOpen = activePopover === popover;
    hideActivePopover();
    if (isAlreadyOpen) return;

    const chip = trigger.closest('li') || trigger;

    popover.style.display = 'block';
    popover.style.position = 'fixed';
    popover.style.visibility = 'hidden';
    activePopover = popover;

    const chipRect = chip.getBoundingClientRect();
    const popoverHeight = popover.offsetHeight;
    const popoverWidth = popover.offsetWidth;
    const gap = 8;
    const padding = 8;

    let top;
    const spaceAbove = chipRect.top;
    if (spaceAbove >= popoverHeight + gap) {
      top = chipRect.top - popoverHeight - gap;
    } else {
      top = Math.min(chipRect.bottom + gap, window.innerHeight - popoverHeight - padding);
    }

    let left = chipRect.left + chipRect.width / 2 - popoverWidth / 2;
    left = Math.max(padding, Math.min(left, window.innerWidth - popoverWidth - padding));

    Object.assign(popover.style, {
      left: `${left}px`,
      top: `${top}px`,
      visibility: 'visible',
    });
  }

  document.querySelectorAll('[data-target]').forEach((trigger) => {
    const targetId = trigger.getAttribute('data-target');
    if (!targetId) return;
    const popover = document.getElementById(targetId);
    if (!popover) return;

    trigger.addEventListener('click', (e) => {
      e.stopPropagation();
      showPopover(trigger, popover);
    });
  });

  document.addEventListener('click', (e) => {
    if (activePopover) {
      const activeTrigger = document.querySelector(`[data-target="${activePopover.id}"]`);
      if (!activePopover.contains(e.target) && (!activeTrigger || !activeTrigger.contains(e.target))) {
        hideActivePopover();
      }
    }
  });

  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && activePopover) {
      hideActivePopover();
    }
  });
});
