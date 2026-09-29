// Square skill-chip popovers. The chip info buttons carry `data-target`; the
// matching popover is toggled via its `hidden` attribute and positioned with
// inline styles. Everything else (theme, icons) was removed for the 1-bit
// redesign.

document.addEventListener('DOMContentLoaded', () => {
  let activePopover = null;
  let activeTrigger = null;

  function hidePopover() {
    if (!activePopover) return;
    activePopover.hidden = true;
    activePopover.style.visibility = '';
    activePopover = null;
    activeTrigger = null;
  }

  function showPopover(trigger, popover) {
    const alreadyOpen = activePopover === popover;
    hidePopover();
    if (alreadyOpen) return;

    // Un-hide (but keep invisible) so it can be measured, then position it.
    popover.hidden = false;
    popover.style.visibility = 'hidden';

    const chip = trigger.closest('li') || trigger;
    const chipRect = chip.getBoundingClientRect();
    const { offsetHeight: height, offsetWidth: width } = popover;
    const gap = 8;
    const padding = 8;

    const top =
      chipRect.top >= height + gap
        ? chipRect.top - height - gap
        : Math.min(chipRect.bottom + gap, window.innerHeight - height - padding);
    const left = Math.max(
      padding,
      Math.min(chipRect.left + chipRect.width / 2 - width / 2, window.innerWidth - width - padding),
    );

    Object.assign(popover.style, { left: `${left}px`, top: `${top}px`, visibility: 'visible' });
    activePopover = popover;
    activeTrigger = trigger;
  }

  document.querySelectorAll('[data-target]').forEach((trigger) => {
    const popover = document.getElementById(trigger.getAttribute('data-target'));
    if (!popover) return;

    trigger.addEventListener('click', (event) => {
      event.stopPropagation();
      showPopover(trigger, popover);
    });
  });

  document.addEventListener('click', (event) => {
    if (activePopover && !activePopover.contains(event.target) && !activeTrigger?.contains(event.target)) {
      hidePopover();
    }
  });

  document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') hidePopover();
  });
});
