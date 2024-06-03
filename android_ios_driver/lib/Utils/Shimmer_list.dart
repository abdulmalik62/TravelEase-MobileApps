import 'package:android_ios_driver/Colours/Colours.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerJobsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).size.width * 0.43),
      child: ListView.builder(
        itemCount: 4, // Number of shimmer items
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.orange[300]!,
            child: _buildJobCard(),
          );
        },
      ),
    );
  }

  Widget _buildJobCard() {

    return Card(
      color: Colours.white,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVerticalLocations(),
            SizedBox(height: 5),
            _buildHorizontalLine(),
            SizedBox(height: 5),
            Row(
              children: [
                Text("    "),
                Spacer(),
                TextButton(
                  onPressed: () {

                  },
                  child: Text("View Route", style: TextStyle(color: Colours.green)),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalLocations() {
    return Column(
      children: [
        Row(
          children: [
            _buildLocationIcon(),
            SizedBox(width: 8),
            Text(""),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _buildDottedLine(),
              ),
            ],
          ),
        ),
        Row(
          children: [
            _buildLocationIcon(),
            SizedBox(width: 8),
            Text(""),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationIcon() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Icon(Icons.location_on, color: Colours.black),
    );
  }

  Widget _buildDottedLine() {
    return Container(
      height: 40,
      child: Column(
        children: List.generate(
          5,
              (index) => Padding(
            padding: const EdgeInsets.all(2.0),
            child: Container(
              width: 2,
              height: 4,
              color: Colours.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalLine() {
    return Container(
      height: 2,
      color: Colours.grey.withOpacity(0.15),
    );
  }
}