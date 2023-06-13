$(document).ready(function () {
    var popup = {
        _$link: null,

        show: function ($link) {
            if (this._$link) {
                this.hide();
            }
            this._$link = $link;
            this._$link.addClass("selected");
            var self = this;
            $.get(this._$link.attr("href"), function (data) {
                $(".popup-content").html(data);
                $(".popup .download a").attr("href", self._$link.attr("href"));
                $(".popup .download a span.name").html(
                    self._$link.attr("href").split("/").pop()
                );
                $(".popup").slideFadeToggle(function () {
                    //can do something here
                    $("body").css("overflow", "hidden");
                });
            });
        },

        hide: function () {
            if (!this._$link) {
                return;
            }
            var self = this;
            $(".popup").slideFadeToggle(function () {
                self._$link.removeClass("selected");
                self._$link = null;
                $("body").css("overflow", "visible");
            });
        }
    };

    $.fn.slideFadeToggle = function (easing, callback) {
        return this.animate(
            { opacity: "toggle", height: "toggle" },
            "fast",
            easing,
            callback
        );
    };

    $(".close").on("click", function (e) {
        popup.hide();
        e.stopPropagation();
    });
    $("body").on("click", function (e) {
        if ($(e.target).parents(".popup").length > 0) {
            return;
        }
        popup.hide();
    });

    function isSelectable(link) {
        var href = $(link).attr("href");

        if (!href) return false;

        if (href.endsWith("sh")) {
            return true;
        }

        if (href.endsWith("config")) {
            return true;
        }

        if (href.endsWith("msmtprc")) {
            return true;
        }

        return false;
    }
    $("a").each(function (idx, link) {
        if (isSelectable(link)) {
            $(link).addClass("selectable");
        }
    });
    $("a").click(function (event) {
        var elem = $(event.target);
        if (!isSelectable(elem)) {
            return true;
        }
        if ($(this).hasClass("selected")) {
            popup.hide();
        } else {
            popup.show($(this));
        }
        return false;
    });
});
