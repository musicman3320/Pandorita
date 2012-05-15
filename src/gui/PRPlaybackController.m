//
//  PRPlaybackController.m
//  Pandorita
//
//  Created by Christopher O'Neill on 5/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PRPlaybackController.h"

#import "PRAppDelegate.h"


@interface PRPlaybackController (PRPlaybackController_Private)

- (void)movieLoadStateDidChange:(NSNotification *)notification;
- (void)movieDidEnd:(NSNotification *)notification;

@end

@implementation PRPlaybackController

- (void)awakeFromNib
{
	player = nil;
}

- (void)finishedLaunching
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieLoadStateDidChange:) name:QTMovieLoadStateDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieDidEnd:) name:QTMovieDidEndNotification object:nil];
	
	updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(updateProgress) userInfo:nil repeats:YES];
}

- (BOOL)isPlaying
{
	return (player && [player rate] > 0);
}

- (BOOL)isSongLoaded
{
	if (player)
	{
		return YES;
	}
	else
	{
		return NO;
	}
}

- (void)playURL:(NSURL *)url
{
	NSError *error = nil;
	
	[self stopPlayback];
	
	player = [[QTMovie alloc] initWithURL:url error:&error];
	ERROR_ON_FAIL(!error);
	
	[self updateControls];
	
error:
	// nothing for now
	return;
}

- (void)togglePause
{
	if (player && [self isPlaying])
	{
		[player stop];
	}
	else if (player)
	{
		[player play];
	}
	
	[self updateControls];
}

- (void)stopPlayback
{
	if (player)
	{
		[player stop];
		RELEASE_MEMBER(player);
	}
	
	[self updateControls];
}

- (void)updateControls
{
	if (player && [self isPlaying])
	{
		[playDockItem setTitle:@"Pause"];
		[playMenuItem setTitle:@"Pause"];
		
		//	[playButton setTitle:@"Pause"];
		[playButton setImage:[NSImage imageNamed:@"pause-off"]];
		[playButton setAlternateImage:[NSImage imageNamed:@"pause-on"]];
		[playButton setEnabled:YES];
		
		[skipButton setEnabled:YES];
		[loveButton setEnabled:YES];
		[banButton setEnabled:YES];
	}
	else if (player)
	{
		[playDockItem setTitle:@"Play"];
		[playMenuItem setTitle:@"Play"];
		
		//	[playButton setTitle:@"Play"];
		[playButton setImage:[NSImage imageNamed:@"play-off"]];
		[playButton setAlternateImage:[NSImage imageNamed:@"play-on"]];
		[playButton setEnabled:YES];
		
		[skipButton setEnabled:YES];
		[loveButton setEnabled:YES];
		[banButton setEnabled:YES];
	}
	else
	{
		[playDockItem setTitle:@"Play"];
		[playMenuItem setTitle:@"Play"];
		
		//	[playButton setTitle:@"Play"];
		[playButton setImage:[NSImage imageNamed:@"play-off"]];
		[playButton setAlternateImage:[NSImage imageNamed:@"play-on"]];
		[playButton setEnabled:NO];
		
		[skipButton setEnabled:NO];
		[loveButton setEnabled:NO];
		[banButton setEnabled:NO];
	}
}

- (void)updateProgress
{
	if (player)
	{
		NSTimeInterval total = [player durationAsInterval];
		NSTimeInterval current = [player currentTimeAsInterval];
		
		[leftField setStringValue:PRSongDurationFromInterval(current)];
	//	[rightField setStringValue:PRSongDurationFromInterval(total - current)];
		[rightField setStringValue:PRSongDurationFromInterval(total)];
		
		[progressView setProgress:(CGFloat)(current / total)];
	}
	else
	{
		[leftField setStringValue:@"0:00"];
		[rightField setStringValue:@"0:00"];
		
		[progressView setProgress:0];
	}
}

- (void)movieLoadStateDidChange:(NSNotification *)notification
{
	// First make sure that this notification is for our movie.
	if ([notification object] == player)
	{
		if ([player rate] == 0)
		{
			// if ([[player attributeForKey:QTMovieLoadStateAttribute] longValue] >= kMovieLoadStatePlaythroughOK)
			// {
			[player play];
			
			[self updateControls];
			[[NSApp delegate] updateDockPlayingInfo];
			[[NSApp delegate] pushGrowlNotification];
			// }
		}
	}
}

- (void)movieDidEnd:(NSNotification *)notification
{
	// First make sure that this notification is for our movie.
	if ([notification object] == player && [player rate] == 0)
	{
		[[NSApp delegate] moveToNextSong:self];
	}
}

- (void)dealloc
{
	[updateTimer invalidate];
	RELEASE_MEMBER(player);
	
	[super dealloc];
}

@end
