import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'InheritedDataProvider.dart';

class BottomNavbar extends StatefulWidget {
  final Widget child;
  final int index;
  final TabController tabController;
  final List<MenuIcon> menu;
  final Color unselectedColor;
  final Color barColor;
  final double end;
  final double start;

  const BottomNavbar({
    super.key,
    required this.child,
    required this.index,
    required this.tabController,
    required this.menu,
    required this.unselectedColor,
    required this.barColor,
    required this.end,
    required this.start,
  });

  @override
  State<BottomNavbar> createState() => _BottomNavbarState();
}

class _BottomNavbarState extends State<BottomNavbar> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  ScrollController scrollBottomBarController = ScrollController();
  bool isScrollingDown = false;
  bool isOnTop = true;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300));
    _offsetAnimation = Tween<Offset>(begin: Offset(0, widget.end), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn))
      ..addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
    _controller.forward();
    myScroll();  // Inicia la escucha del scroll
  }

  // Función para mostrar la barra
  void showBottomBar() {
    if (mounted) {
      setState(() {
        _controller.forward();
      });
    }
  }

  // Función para ocultar la barra
  void hideBottomBar() {
    if (mounted) {
      setState(() {
        _controller.reverse();
      });
    }
  }

  // Escuchar el scroll para ocultar o mostrar la barra
  Future<void> myScroll() async {
    scrollBottomBarController.addListener(() {
      if (scrollBottomBarController.position.userScrollDirection == ScrollDirection.reverse) {
        if (!isScrollingDown) {
          isScrollingDown = true;
          isOnTop = false;
          hideBottomBar();
        }
      }

      if (scrollBottomBarController.position.userScrollDirection == ScrollDirection.forward) {
        if (isScrollingDown) {
          isScrollingDown = false;
          isOnTop = true;
          showBottomBar();
        }
      }
    });
  }

  @override
  void dispose() {
    scrollBottomBarController.removeListener(() {});
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.bottomCenter,
      children: [
        InheritedDataProvider(
          scrollController: scrollBottomBarController,
          child: widget.child,
        ),
        Positioned(
          bottom: widget.start,
          child: SlideTransition(
            position: _offsetAnimation,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(500),
              child: Container(
                width: MediaQuery.of(context).size.width - 24,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(500),
                  border: Border.all(color: widget.barColor, width: 0),
                ),
                child: Material(
                  color: widget.barColor,
                  elevation: .0,
                  type: MaterialType.transparency,
                  surfaceTintColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  child: Center(
                    child: TabBar(
                      controller: widget.tabController,
                      indicator: BoxDecoration(),
                      labelColor: widget.unselectedColor, // Color del texto cuando la pestaña está seleccionada
                      unselectedLabelColor: widget.unselectedColor, // Color del texto cuando no está seleccionada
                      indicatorColor: Colors.transparent, // No mostrar el indicador debajo
                      tabs: widget.menu,
                    ),
                  ),
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}
class MenuIcon extends StatelessWidget {
  final Widget icon;
  final double? height;
  final double? width;
  final Widget label;
  final Color? color;

  const MenuIcon({
    super.key,
    required this.icon,
    this.width,
    this.height,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          IconTheme(
            data: IconThemeData(color: color ?? Colors.white),
            child: icon,
          ),
          label,
        ],
      ),
    );
  }

}

