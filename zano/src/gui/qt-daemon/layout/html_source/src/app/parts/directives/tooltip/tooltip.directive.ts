import {
  Directive,
  ElementRef,
  EventEmitter,
  HostBinding,
  HostListener,
  Input,
  OnDestroy,
  Output,
  Renderer2,
  SecurityContext,
} from '@angular/core';
import { DomSanitizer } from '@angular/platform-browser';

@Directive({
  // eslint-disable-next-line
  selector: '[tooltip]',
})
export class TooltipDirective implements OnDestroy {
  @HostBinding('style.cursor') cursor;

  @Input('tooltip') tooltipInner: any;

  @Input() placement: string;

  @Input() tooltipClass: string;

  @Input() timeout = 0;

  @Input() timeDelay = 0;

  @Input() delay = 0;

  @Input() showWhenNoOverflow = true;

  @Output() eventHide = new EventEmitter<boolean>();

  tooltip: HTMLElement;

  removeTooltipTimeout;

  removeTooltipTimeoutInner;

  removeTooltipTimeDelay;

  private enter: (event: MouseEvent) => void;

  private leave: (event: MouseEvent) => void;

  constructor(private el: ElementRef, private renderer: Renderer2, private sanitizer: DomSanitizer) {}

  @HostListener('mouseenter') onMouseEnter(): void {
    if (!this.tooltipInner) {
      return;
    }
    if (this.showWhenNoOverflow || (!this.showWhenNoOverflow && this.el.nativeElement.offsetWidth < this.el.nativeElement.scrollWidth)) {
      this.cursor = 'pointer';
      if (!this.tooltip) {
        if (this.timeDelay !== 0) {
          this.removeTooltipTimeDelay = setTimeout(() => {
            this.show();
          }, this.timeDelay);
        } else {
          this.show();
        }
      } else {
        this.cancelHide();
      }
    }
  }

  @HostListener('mouseleave') onMouseLeave(): void {
    clearTimeout(this.removeTooltipTimeDelay);
    if (this.tooltip) {
      this.hide();
    }
  }

  show(): void {
    this.create();
    this.placement = this.placement === null ? 'top' : this.placement;
    this.setPosition(this.placement);
  }

  hide(): void {
    this.removeTooltipTimeout = setTimeout(() => {
      this.renderer.setStyle(this.tooltip, 'opacity', '0');
      this.removeTooltipTimeoutInner = setTimeout(() => {
        this.renderer.removeChild(document.body, this.tooltip);
        this.tooltip.removeEventListener('mouseenter', this.enter);
        this.tooltip.removeEventListener('mouseleave', this.leave);
        this.tooltip = null;
        this.eventHide.emit(true);
      }, this.delay);
    }, this.timeout);
  }

  cancelHide(): void {
    clearTimeout(this.removeTooltipTimeout);
    clearTimeout(this.removeTooltipTimeoutInner);
    this.renderer.setStyle(this.tooltip, 'opacity', '1');
  }

  create(): void {
    this.tooltip = this.renderer.createElement('div');
    let innerBlock = this.renderer.createElement('div');
    if (typeof this.tooltipInner === 'string') {
      innerBlock.innerText = this.sanitizer.sanitize(SecurityContext.HTML, this.tooltipInner);
    } else {
      if (this.tooltipInner) {
        innerBlock = this.tooltipInner;
      }
    }
    this.renderer.addClass(innerBlock, 'tooltip-inner');
    this.renderer.addClass(innerBlock, 'scrolled-content');
    this.renderer.appendChild(this.tooltip, innerBlock);
    this.renderer.appendChild(document.body, this.tooltip);

    this.enter = (): void => {
      this.cancelHide();
    };
    this.tooltip.addEventListener('mouseenter', this.enter);
    this.leave = (): void => {
      if (this.tooltip) {
        this.hide();
      }
    };
    this.tooltip.addEventListener('mouseleave', this.leave);

    this.renderer.setStyle(document.body, 'position', 'relative');
    this.renderer.setStyle(this.tooltip, 'position', 'absolute');
    if (this.tooltipClass !== null) {
      const classes = this.tooltipClass.split(' ');
      for (let i = 0; i < classes.length; i++) {
        this.renderer.addClass(this.tooltip, classes[i]);
      }
    }
    this.renderer.setStyle(this.tooltip, 'opacity', '0');
    this.renderer.setStyle(this.tooltip, '-webkit-transition', `opacity ${this.delay}ms`);
    this.renderer.setStyle(this.tooltip, '-moz-transition', `opacity ${this.delay}ms`);
    this.renderer.setStyle(this.tooltip, '-o-transition', `opacity ${this.delay}ms`);
    this.renderer.setStyle(this.tooltip, 'transition', `opacity ${this.delay}ms`);
    window.setTimeout(() => {
      return this.tooltip && this.renderer.setStyle(this.tooltip, 'opacity', '1');
    }, 0);
  }

  setPosition(placement): void {
    const hostPos = this.el.nativeElement.getBoundingClientRect();
    this.renderer.addClass(this.tooltip, 'ng-tooltip-' + placement);
    const topExit = hostPos.top - this.tooltip.getBoundingClientRect().height - parseInt(getComputedStyle(this.tooltip).marginTop, 10) < 0;
    const bottomExit =
      window.innerHeight <
      hostPos.bottom + this.tooltip.getBoundingClientRect().height + parseInt(getComputedStyle(this.tooltip).marginTop, 10);

    switch (placement) {
      case 'top':
        if (topExit) {
          this.renderer.removeClass(this.tooltip, 'ng-tooltip-' + placement);
          this.setPosition('bottom');
          return;
        } else {
          this.renderer.setStyle(
            this.tooltip,
            'left',
            hostPos.left + (hostPos.right - hostPos.left) / 2 - this.tooltip.getBoundingClientRect().width / 2 + 'px'
          );
          this.renderer.setStyle(this.tooltip, 'top', hostPos.top - this.tooltip.getBoundingClientRect().height + 'px');
          this.checkSides();
        }
        break;
      case 'top-left':
        if (topExit) {
          this.renderer.removeClass(this.tooltip, 'ng-tooltip-' + placement);
          this.setPosition('bottom-left');
          return;
        } else {
          this.renderer.setStyle(this.tooltip, 'left', hostPos.left + 'px');
          this.renderer.setStyle(this.tooltip, 'top', hostPos.top - this.tooltip.getBoundingClientRect().height + 'px');
          this.checkSides();
        }
        break;
      case 'top-right':
        if (topExit) {
          this.renderer.removeClass(this.tooltip, 'ng-tooltip-' + placement);
          this.setPosition('bottom-right');
          return;
        } else {
          this.renderer.setStyle(this.tooltip, 'left', hostPos.right - this.tooltip.offsetWidth + 'px');
          this.renderer.setStyle(this.tooltip, 'top', hostPos.top - this.tooltip.getBoundingClientRect().height + 'px');
          this.checkSides();
        }
        break;
      case 'bottom':
        if (bottomExit) {
          this.renderer.removeClass(this.tooltip, 'ng-tooltip-' + placement);
          this.setPosition('top');
          return;
        } else {
          this.renderer.setStyle(this.tooltip, 'top', hostPos.bottom + 'px');
          this.renderer.setStyle(
            this.tooltip,
            'left',
            hostPos.left + (hostPos.right - hostPos.left) / 2 - this.tooltip.getBoundingClientRect().width / 2 + 'px'
          );
          this.checkSides();
        }
        break;
      case 'bottom-left':
        if (bottomExit) {
          this.renderer.removeClass(this.tooltip, 'ng-tooltip-' + placement);
          this.setPosition('top-left');
          return;
        } else {
          this.renderer.setStyle(this.tooltip, 'top', hostPos.bottom + 'px');
          this.renderer.setStyle(this.tooltip, 'left', hostPos.left + 'px');
          this.checkSides();
        }
        break;
      case 'bottom-right':
        if (bottomExit) {
          this.renderer.removeClass(this.tooltip, 'ng-tooltip-' + placement);
          this.setPosition('top-right');
          return;
        } else {
          this.renderer.setStyle(this.tooltip, 'top', hostPos.bottom + 'px');
          this.renderer.setStyle(this.tooltip, 'left', hostPos.right - this.tooltip.offsetWidth + 'px');
          this.checkSides();
        }
        break;
      case 'left':
        this.renderer.setStyle(this.tooltip, 'left', hostPos.left - this.tooltip.getBoundingClientRect().width + 'px');
        this.renderer.setStyle(
          this.tooltip,
          'top',
          hostPos.top + (hostPos.bottom - hostPos.top) / 2 - this.tooltip.getBoundingClientRect().height / 2 + 'px'
        );
        break;
      case 'left-top':
        this.renderer.setStyle(this.tooltip, 'top', hostPos.top + 'px');
        this.renderer.setStyle(this.tooltip, 'left', hostPos.left - this.tooltip.getBoundingClientRect().width + 'px');
        break;
      case 'left-bottom':
        this.renderer.setStyle(this.tooltip, 'left', hostPos.left - this.tooltip.getBoundingClientRect().width + 'px');
        this.renderer.setStyle(this.tooltip, 'top', hostPos.bottom - this.tooltip.getBoundingClientRect().height + 'px');
        break;
      case 'right':
        this.renderer.setStyle(this.tooltip, 'left', hostPos.right + 'px');
        this.renderer.setStyle(
          this.tooltip,
          'top',
          hostPos.top + (hostPos.bottom - hostPos.top) / 2 - this.tooltip.getBoundingClientRect().height / 2 + 'px'
        );
        break;
      case 'right-top':
        this.renderer.setStyle(this.tooltip, 'top', hostPos.top + 'px');
        this.renderer.setStyle(this.tooltip, 'left', hostPos.right + 'px');
        break;
      case 'right-bottom':
        this.renderer.setStyle(this.tooltip, 'left', hostPos.right + 'px');
        this.renderer.setStyle(this.tooltip, 'top', hostPos.bottom - this.tooltip.getBoundingClientRect().height + 'px');
        break;
    }
  }

  checkSides(): void {
    if (this.tooltip.getBoundingClientRect().left < 0) {
      this.renderer.setStyle(this.tooltip, 'left', 0);
    }
    if (this.tooltip.getBoundingClientRect().right > window.innerWidth) {
      this.renderer.setStyle(this.tooltip, 'left', window.innerWidth - this.tooltip.getBoundingClientRect().width + 'px');
    }
  }

  ngOnDestroy(): void {
    clearTimeout(this.removeTooltipTimeout);
    clearTimeout(this.removeTooltipTimeoutInner);
    clearTimeout(this.removeTooltipTimeDelay);
    if (this.tooltip) {
      this.renderer.removeChild(document.body, this.tooltip);
      this.tooltip = null;
    }
  }
}
